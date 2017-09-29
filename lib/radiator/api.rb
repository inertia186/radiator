require 'uri'
require 'base64'
require 'hashie'
require 'hashie/logger'
require 'openssl'
require 'net/http/persistent'

module Radiator
  class Api
    DEFAULT_URL = 'https://steemd.steemit.com'
    
    DEFAULT_FAILOVER_URLS = [
      DEFAULT_URL,
      'https://steemd.steemitdev.com',
      'https://steemd-int.steemit.com',
      'https://steemd.steemitstage.com',
      'https://gtg.steem.house:8090',
      "https://seed.bitcoiner.me",
      "https://steemd.minnowsupportproject.org",
      "https://steemd.privex.io",
      'https://rpc.steemliberator.com'
    ]
    
    POST_HEADERS = {
      'Content-Type' => 'application/json'
    }
    
    def initialize(options = {})
      @user = options[:user]
      @password = options[:password]
      @url = options[:url] || DEFAULT_URL
      @preferred_url = @url.dup
      @failover_urls = options[:failover_urls] || (DEFAULT_FAILOVER_URLS - [@url])
      @preferred_failover_urls = @failover_urls.dup
      @debug = !!options[:debug]
      @logger = options[:logger] || Radiator.logger
      @hashie_logger = options[:hashie_logger] || Logger.new(nil)
      
      unless @hashie_logger.respond_to? :warn
        @hashie_logger = Logger.new(@hashie_logger)
      end
      
      @recover_transactions_on_error = if options.keys.include? :recover_transactions_on_error
        options[:recover_transactions_on_error]
      else
        true
      end
      
      Hashie.logger = @hashie_logger
      @method_names = nil
      @api_options = options.dup
    end
    
    def method_names
      return @method_names if !!@method_names
      
      @method_names = Radiator::Api.methods(api_name).map do |e|
        e['method'].to_sym
      end
    end
    
    def api_name
      :database_api
    end
    
    # Get a specific block or range of blocks.
    # 
    # @param block_number [Fixnum || Array<Fixnum>]
    # @param block the block to execute for each result, optional.
    # @return [Array]
    def get_blocks(block_number, &block)
      block_number = [*(block_number)].flatten
      
      if !!block
        block_number.each do |i|
          yield api.get_block(i).result, i
        end
      else
        block_number.map do |i|
          api.get_block(i).result
        end
      end
    end
    
    # Find a specific block
    # 
    # @param block_number [Fixnum]
    # @param block the block to execute for each result, optional.
    # @return [Hash]
    def find_block(block_number, &block)
      if !!block
        yield api.get_blocks(block_number).first
      else
        api.get_blocks(block_number).first
      end
    end
    
    def find_account(id, &block)
      if !!block
        yield api.get_accounts([id]).result.first
      else
        api.get_accounts([id]).result.first
      end
    end
    
    def base_per_mvest
      api.get_dynamic_global_properties do |properties|
        total_vesting_fund_steem = properties.total_vesting_fund_steem.to_f
        total_vesting_shares_mvest = properties.total_vesting_shares.to_f / 1e6
      
        total_vesting_fund_steem / total_vesting_shares_mvest
      end
    end
    
    alias steem_per_mvest base_per_mvest
    
    def base_per_debt
      get_feed_history do |feed_history|
        current_median_history = feed_history.current_median_history
        base = current_median_history.base
        base = base.split(' ').first.to_f
        quote = current_median_history.quote
        quote = quote.split(' ').first.to_f

        (base / quote) * steem_per_mvest
      end
    end
    
    alias steem_per_usd base_per_debt
    
    def respond_to_missing?(m, include_private = false)
      method_names.include?(m.to_sym)
    end
    
    def method_missing(m, *args, &block)
      super unless respond_to_missing?(m)
      
      response = nil
      options = {
        jsonrpc: "2.0",
        params: [api_name, m, args],
        id: rpc_id,
        method: "call"
      }
      
      tries = 0
      timestamp = Time.now.utc
      
      loop do
        tries += 1
        
        begin
          if @recover_transactions_on_error
            signatures = extract_signatures(options)
            
            if tries > 1 && !!signatures && signatures.any?
              if !!(response = recover_transaction(signatures, rpc_id, timestamp))
                @logger.warn 'Found recovered transaction after retry.'
                response = Hashie::Mash.new(response)
              end
            end
          end
          
          response = request(options)
          
          if response.nil?
            @logger.error "No response, retrying ..."
            backoff
            redo
          elsif !response.kind_of? Net::HTTPSuccess
            @logger.warn "Unexpected response: #{response.inspect}"
            backoff
            redo
          end
          
          response = case response.code
          when '200'
            body = response.body
            response = JSON[body]
            
            if response.keys.include?('result') && response['result'].nil?
              @logger.warn 'Invalid response from node, retrying ...'; nil
            else
              Hashie::Mash.new(response)
            end
          when '400' then @logger.warn 'Code 400: Bad Request, retrying ...'; nil
          when '502' then @logger.warn 'Code 502: Bad Gateway, retrying ...'; nil
          when '503' then @logger.warn 'Code 503: Service Unavailable, retrying ...'; nil
          when '504' then @logger.warn 'Code 504: Gateway Timeout, retrying ...'; nil
          else
            @logger.warn "Unknown code #{response.code}, retrying ..."
            ap response
          end
        rescue Net::HTTP::Persistent::Error => e
          @logger.warn "Unable to perform request: #{e} :: #{!!e.cause ? "cause: #{e.cause.message}" : ''}"
          @wakka = true
        rescue Errno::ECONNREFUSED => e
          @logger.warn 'Connection refused, retrying ...'
        rescue Errno::EADDRNOTAVAIL => e
          @logger.warn 'Node not available, retrying ...'
        rescue Net::ReadTimeout => e
          @logger.warn 'Node read timeout, retrying ...'
        rescue Net::OpenTimeout => e
          @logger.warn 'Node timeout, retrying ...'
        rescue RangeError => e
          @logger.warn 'Range Error, retrying ...'
        rescue OpenSSL::SSL::SSLError => e
          @logger.warn "SSL Error (#{e.message}), retrying ..."
        rescue SocketError => e
          @logger.warn "Socket Error (#{e.message}), retrying ..."
        rescue JSON::ParserError => e
          @logger.warn "JSON Parse Error (#{e.message}), retrying ..."
        rescue => e
          @logger.warn "Unknown exception from request ..."
          ap e if defined? ap
        end
        
        if !!response
          if !!block
            return yield(response.result, response.error, response.id)
          else
            return response
          end
        end

        backoff
      end # loop
    end
    
    def shutdown
      @http.shutdown if !!@http && defined?(@http.shutdown)
      @http = nil
    end
  private
    def self.methods_json_path
      @methods_json_path ||= "#{File.dirname(__FILE__)}/methods.json"
    end
    
    def self.methods(api_name)
      @methods ||= {}
      @methods[api_name] ||= JSON[File.read methods_json_path].map do |e|
        e if e['api'].to_sym == api_name
      end.compact.freeze
    end
    
    def api
      @api ||= self.class == Api ? self : Api.new(@api_options)
    end

    def rpc_id
      @rpc_id ||= 0
      @rpc_id = @rpc_id + 1
    end
    
    def uri
      @uri ||= URI.parse(@url)
    end
    
    def http
      @http_id ||= "radiator-#{Radiator::VERSION}-#{self.class.name.downcase}"
      @http ||= Net::HTTP::Persistent.new(@http_id).tap do |http|
        http.retry_change_requests = true
        http.max_requests = 30
        http.read_timeout = 10
        http.open_timeout = 10
      end
    end
    
    def post_request
      Net::HTTP::Post.new uri.request_uri, POST_HEADERS
    end
    
    def request(options)
      request = post_request
      request.body = JSON[options]
      http.request(uri, request)
    end
    
    def extract_signatures(options)
      return unless options[:params].include? :network_broadcast_api
      
      options[:params].map do |param|
        next unless defined? param.map
        
        param.map { |tx| tx[:signatures] }
      end.flatten.compact
    end
    
    def recover_transaction(signatures, rpc_id, after)
      now = Time.now.utc
      block_range = api.get_dynamic_global_properties do |properties|
        high = properties.head_block_number
        low = high - 100
        [*(low..(high))].reverse
      end
      
      # It would be nice if Steemit, Inc. would add an API method like
      # `get_transaction`, call it `get_transaction_by_signature`, so we didn't
      # have to scan the latest blocks like this.  At most, we read 100 blocks
      # but we also give up once the block time is before the `after` argument.
      
      api.get_blocks(block_range) do |block, block_num|
        raise "Race condition detected at: #{block_num}" if block.nil?
        
        timestamp = Time.parse(block.timestamp + 'Z')
        break if timestamp < after
        
        block.transactions.each_with_index do |tx, index|
          next unless ((tx['signatures'] || []) & signatures).any?
          
          puts "Found matching signatures in #{(Time.now.utc - now)} seconds: #{signatures}"
          ap tx
          
          return {
            id: rpc_id,
            result: {
              id: block.transaction_ids[index],
              block_num: block_num,
              trx_num: index,
              expired: false
            }
          }
        end
      end
      
      puts "Took #{(Time.now.utc - now)} seconds to scan for signatures."
    end
    
    def reset_failover
      @url = @preferred_url.dup
      @failover_urls = @preferred_failover_urls.dup
      @logger.warn "Failover reset, going back to #{@url} ..."
    end
    
    def pop_failover_url
      @failover_urls.delete(@failover_urls.sample) || @url
    end
    
    def bump_failover
      reset_failover if @failover_urls.none?
      
      @uri = nil
      @url = pop_failover_url
      @logger.warn "Failing over to #{@url} ..."
    end
    
    def backoff
      shutdown
      bump_failover if !!@backoff_at && Time.now - @backoff_at < 300
      @backoff_at ||= Time.now
      @backoff_sleep ||= 0.01
      
      @backoff_sleep *= 2
      sleep @backoff_sleep
      
      if Time.now - @backoff_at > 300
        @backoff_at = nil 
        @backoff_sleep = nil
      end
    end
  end
end
