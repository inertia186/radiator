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
      @net_http_persistent_enabled = true
      @logger = options[:logger] || Radiator.logger
      @hashie_logger = options[:hashie_logger] || Logger.new(nil)
      
      unless @hashie_logger.respond_to? :warn
        @hashie_logger = Logger.new(@hashie_logger)
      end
      
      Hashie.logger = @hashie_logger
      @method_names = nil
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
          yield get_block(i).result, i
        end
      else
        block_number.map do |i|
          get_block(i).result
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
        yield get_blocks(block_number).first
      else
        get_blocks(block_number).first
      end
    end
    
    def find_account(id, &block)
      if !!block
        yield get_accounts([id]).result.first
      else
        get_accounts([id]).result.first
      end
    end
    
    # TODO: Need to rename this to base_per_mvest and alias to steem_per_mvest
    def steem_per_mvest
      properties = get_dynamic_global_properties.result
      
      total_vesting_fund_steem = properties.total_vesting_fund_steem.to_f
      total_vesting_shares_mvest = properties.total_vesting_shares.to_f / 1e6
      
      total_vesting_fund_steem / total_vesting_shares_mvest
    end
    
    # TODO: Need to rename this to base_per_debt and alias to steem_per_debt
    def steem_per_usd
      feed_history = get_feed_history.result

      current_median_history = feed_history.current_median_history
      base = current_median_history.base
      base = base.split(' ').first.to_f
      quote = current_median_history.quote
      quote = quote.split(' ').first.to_f

      (base / quote) * steem_per_mvest
    end
    
    def respond_to_missing?(m, include_private = false)
      method_names.include?(m.to_sym)
    end
    
    def method_missing(m, *args, &block)
      super unless respond_to_missing?(m)
      
      options = {
        jsonrpc: "2.0",
        params: [api_name, m, args],
        id: rpc_id,
        method: "call"
      }
      
      loop do
        begin
          response = request(options)
          
          if response.nil?
            @logger.error "No response, retrying ..."
            backoff
            redo
          end
          
          case response.code
          when '200'
            response = JSON[response.body]
            
            return Hashie::Mash.new(response)
          when '400'
            @logger.warn 'Code 400: Bad Request, retrying ...'
          when '502'
            @logger.warn 'Code 502: Bad Gateway, retrying ...'
          when '503'
            @logger.warn 'Code 503: Service Unavailable, retrying ...'
          when '504'
            @logger.warn 'Code 504: Gateway Timeout, retrying ...'
          else
            @logger.warn "Unknown code #{response.code}, retrying ..."
            ap response
          end
          
          backoff
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
          ap e
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
      if !!@net_http_persistent_enabled
        begin
          request = post_request
          request.body = JSON[options]
          response = http.request(uri, request)
          
          return response if response.kind_of? Net::HTTPSuccess
          @logger.warn "Unexpeced response: #{response.inspect}; temporarily falling back to non-persistent-http"
          backoff
          @net_http_persistent_enabled = false
        rescue Net::HTTP::Persistent::Error => e
          @logger.warn "Unable to perform request: #{request} :: #{e} :: #{!!e.cause ? "cause: #{e.cause.message}" : ''}; temporarily falling back to non-persistent-http"
          backoff
          @net_http_persistent_enabled = false
        end
      end
        
      unless @net_http_persistent_enabled
        non_persistent_http = Net::HTTP.new(uri.host, uri.port)
        non_persistent_http.use_ssl = true
        non_persistent_http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = post_request
        request.body = JSON[options]
        
        # Try to go back to http persistent on next request.
        @net_http_persistent_enabled = true
        
        non_persistent_http.request(request)
      end
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
