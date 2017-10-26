require 'uri'
require 'base64'
require 'hashie'
require 'hashie/logger'
require 'openssl'
require 'open-uri'
require 'net/http/persistent'

module Radiator
  # Radiator::Api allows you to call remote methods to interact with the STEEM
  # blockchain.  The `Api` class is a shortened name for
  # `Radiator::DatabaseApi`.
  #
  # Examples:
  #
  #   api = Radiator::Api.new
  #   response = api.get_dynamic_global_properties
  #   virtual_supply = response.result.virtual_supply
  #
  # ... or ...
  #
  #   api = Radiator::Api.new
  #   virtual_supply = api.get_dynamic_global_properties do |prop|
  #     prop.virtual_supply
  #   end
  #
  # If you need access to the `error` property, they can be accessed as follows:
  #
  #   api = Radiator::Api.new
  #   response = api.get_dynamic_global_properties
  #   if response.result.nil?
  #     puts response.error
  #     exit
  #   end
  #   
  #   virtual_supply = response.result.virtual_supply
  #
  # ... or ...
  #
  #   api = Radiator::Api.new
  #   virtual_supply = api.get_dynamic_global_properties do |prop, error|
  #     if prop.nil?
  #       puts error
  #       exis
  #     end
  #     
  #     prop.virtual_supply
  #   end
  #
  # List of remote methods:
  #
  #   set_subscribe_callback
  #   set_pending_transaction_callback
  #   set_block_applied_callback
  #   cancel_all_subscriptions
  #   get_trending_tags
  #   get_tags_used_by_author
  #   get_post_discussions_by_payout
  #   get_comment_discussions_by_payout
  #   get_discussions_by_trending
  #   get_discussions_by_trending30
  #   get_discussions_by_created
  #   get_discussions_by_active
  #   get_discussions_by_cashout
  #   get_discussions_by_payout
  #   get_discussions_by_votes
  #   get_discussions_by_children
  #   get_discussions_by_hot
  #   get_discussions_by_feed
  #   get_discussions_by_blog
  #   get_discussions_by_comments
  #   get_discussions_by_promoted
  #   get_block_header
  #   get_block
  #   get_ops_in_block
  #   get_state
  #   get_trending_categories
  #   get_best_categories
  #   get_active_categories
  #   get_recent_categories
  #   get_config
  #   get_dynamic_global_properties
  #   get_chain_properties
  #   get_feed_history
  #   get_current_median_history_price
  #   get_witness_schedule
  #   get_hardfork_version
  #   get_next_scheduled_hardfork
  #   get_accounts
  #   get_account_references
  #   lookup_account_names
  #   lookup_accounts
  #   get_account_count
  #   get_conversion_requests
  #   get_account_history
  #   get_owner_history
  #   get_recovery_request
  #   get_escrow
  #   get_withdraw_routes
  #   get_account_bandwidth
  #   get_savings_withdraw_from
  #   get_savings_withdraw_to
  #   get_order_book
  #   get_open_orders
  #   get_liquidity_queue
  #   get_transaction_hex
  #   get_transaction
  #   get_required_signatures
  #   get_potential_signatures
  #   verify_authority
  #   verify_account_authority
  #   get_active_votes
  #   get_account_votes
  #   get_content
  #   get_content_replies
  #   get_discussions_by_author_before_date
  #   get_replies_by_last_update
  #   get_witnesses
  #   get_witness_by_account
  #   get_witnesses_by_vote
  #   lookup_witness_accounts
  #   get_witness_count
  #   get_active_witnesses
  #   get_miner_queue
  #   get_reward_fund
  #
  # These methods and their characteristics are copied directly from methods
  # marked as `database_api` in `steem-js`:
  #
  # https://raw.githubusercontent.com/steemit/steem-js/master/src/api/methods.js
  #
  # @see https://steemit.github.io/steemit-docs/#accounts
  #
  class Api
    include Utils
    
    DEFAULT_STEEM_URL = 'https://api.steemit.com'
    
    DEFAULT_GOLOS_URL = 'https://ws.golos.io'
    
    DEFAULT_STEEM_FAILOVER_URLS = [
      DEFAULT_STEEM_URL,
      'https://api.steemitstage.com',
      'https://gtg.steem.house:8090',
      'https://seed.bitcoiner.me',
      'https://steemd.minnowsupportproject.org',
      'https://steemd.privex.io',
      'https://rpc.steemliberator.com'
    ]
    
    DEFAULT_GOLOS_FAILOVER_URLS = [
      DEFAULT_GOLOS_URL,
      'https://api.golos.cf'
    ]
    
    # @private
    POST_HEADERS = {
      'Content-Type' => 'application/json'
    }
    
    # @private
    HEALTH_URI = '/health'
    
    def self.default_url(chain)
      case chain.to_sym
      when :steem then DEFAULT_STEEM_URL
      when :golos then DEFAULT_GOLOS_URL
      else; raise ApiError, "Unsupported chain: #{chain}"
      end
    end
    
    def self.default_failover_urls(chain)
      case chain.to_sym
      when :steem then DEFAULT_STEEM_FAILOVER_URLS
      when :golos then DEFAULT_GOLOS_FAILOVER_URLS
      else; raise ApiError, "Unsupported chain: #{chain}"
      end
    end
    
    # Cretes a new instance of Radiator::Api.
    #
    # Examples:
    #
    #   api = Radiator::Api.new(url: 'https://api.example.com')
    #
    # @param options [Hash] The attributes to initialize the Radiator::Api with.
    # @option options [String] :url URL that points at a full node, like `https://api.steemit.com`.  Default from DEFAULT_URL.
    # @option options [Array<String>] :failover_urls An array that contains one or more full nodes to fall back on.  Default from DEFAULT_FAILOVER_URLS.
    # @option options [Logger] :logger An instance of `Logger` to send debug messages to.
    # @option options [Boolean] :recover_transactions_on_error Have Radiator try to recover transactions that are accepted but could not be confirmed due to an error like network timeout.  Default: `true`
    # @option options [Integer] :max_requests Maximum number of requests on a connection before it is considered expired and automatically closed.
    # @option options [Integer] :pool_size Maximum number of connections allowed.
    # @option options [Boolean] :reuse_ssl_sessions Reuse a previously opened SSL session for a new connection.  There's a slight performance improvement by enabling this, but at the expense of reliability during long execution.  Default false.
    def initialize(options = {})
      @user = options[:user]
      @password = options[:password]
      @chain = options[:chain] || :steem
      @url = options[:url] || Api::default_url(@chain)
      @preferred_url = @url.dup
      @failover_urls = options[:failover_urls]
      @debug = !!options[:debug]
      @logger = options[:logger] || Radiator.logger
      @hashie_logger = options[:hashie_logger] || Logger.new(nil)
      @max_requests = options[:max_requests] || 30
      @ssl_verify_mode = options[:ssl_verify_mode] || OpenSSL::SSL::VERIFY_PEER
      @reuse_ssl_sessions = !!options[:reuse_ssl_sessions]
      @ssl_version = options[:ssl_version]
      
      if @failover_urls.nil?
        @failover_urls = Api::default_failover_urls(@chain) - [@url]
      end
      
      @failover_urls = [@failover_urls].flatten.compact
      @preferred_failover_urls = @failover_urls.dup
      
      unless @hashie_logger.respond_to? :warn
        @hashie_logger = Logger.new(@hashie_logger)
      end
      
      @recover_transactions_on_error = if options.keys.include? :recover_transactions_on_error
        options[:recover_transactions_on_error]
      else
        true
      end
      
      if defined? Net::HTTP::Persistent::DEFAULT_POOL_SIZE
        @pool_size = options[:pool_size] || Net::HTTP::Persistent::DEFAULT_POOL_SIZE
      end
      
      Hashie.logger = @hashie_logger
      @method_names = nil
      @http = nil
      @api_options = options.dup.merge(chain: @chain)
      @api = nil
      @block_api = nil
      @backoff_at = nil
    end
    
    # Get a specific block or range of blocks.
    #
    # Example:
    #
    #   api = Radiator::Api.new
    #   blocks = api.get_blocks(10..20)
    #   transactions = blocks.flat_map(&:transactions)
    #
    # ... or ...
    #
    #   api = Radiator::Api.new
    #   transactions = []
    #   api.get_blocks(10..20) do |block|
    #     transactions += block.transactions
    #   end
    #
    # @param block_number [Fixnum || Array<Fixnum>]
    # @param block the block to execute for each result, optional.
    # @return [Array]
    def get_blocks(block_number, &block)
      block_number = [*(block_number)].flatten
      
      if !!block
        block_number.each do |i|
          yield block_api.get_block(i).result, i
        end
      else
        block_number.map do |i|
          block_api.get_block(i).result
        end
      end
    end
    
    # Find a specific block.
    #
    # Example:
    #
    #   api = Radiator::Api.new
    #   block = api.find_block(12345678)
    #   transactions = block.transactions
    #
    # ... or ...
    #
    #   api = Radiator::Api.new
    #   transactions = api.find_block(12345678) do |block|
    #     block.transactions
    #   end
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
    
    # Find a specific account.
    #
    # Example:
    #
    #   api = Radiator::Api.new
    #   ned = api.find_account('ned')
    #   vesting_shares = ned.vesting_shares
    #
    # ... or ...
    #
    #   api = Radiator::Api.new
    #   vesting_shares = api.find_account('ned') do |ned|
    #     ned.vesting_shares
    #   end
    # 
    # @param id [String] Name of the account to find.
    # @param block the block to execute for each result, optional.
    # @return [Hash]
    def find_account(id, &block)
      if !!block
        yield api.get_accounts([id]).result.first
      else
        api.get_accounts([id]).result.first
      end
    end
    
    # Returns the current base (STEEM) price in the vest asset (VESTS).
    #
    def base_per_mvest
      api.get_dynamic_global_properties do |properties|
        total_vesting_fund_steem = properties.total_vesting_fund_steem.to_f
        total_vesting_shares_mvest = properties.total_vesting_shares.to_f / 1e6
      
        total_vesting_fund_steem / total_vesting_shares_mvest
      end
    end
    
    alias steem_per_mvest base_per_mvest
    
    # Returns the current base (STEEM) price in the debt asset (SBD).
    #
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
    
    # Stops the persistant http connections.
    #
    def shutdown
      @uri = nil
      @http_id = nil
      @http.shutdown if !!@http && defined?(@http.shutdown)
      @http = nil
      @api.shutdown if !!@api && @api != self
      @api = nil
      @block_api.shutdown if !!@block_api && @block_api != self
      @block_api = nil
    end
    
    # @private
    def method_names
      return @method_names if !!@method_names
      
      @method_names = Radiator::Api.methods(api_name).map do |e|
        e['method'].to_sym
      end
    end
    
    # @private
    def api_name
      :database_api
    end
    
    # @private
    def respond_to_missing?(m, include_private = false)
      method_names.include?(m.to_sym)
    end
    
    # @private
    def method_missing(m, *args, &block)
      super unless respond_to_missing?(m)
      
      current_rpc_id = rpc_id
      method_name = [api_name, m].join('.')
      response = nil
      options = {
        jsonrpc: "2.0",
        params: [api_name, m, args],
        id: current_rpc_id,
        method: "call"
      }
      
      tries = 0
      timestamp = Time.now.utc
      
      loop do
        tries += 1
        
        begin
          if tries > 1 && @recover_transactions_on_error && api_name == :network_broadcast_api
            signatures, exp = extract_signatures(options)
            
            if !!signatures && signatures.any?
              offset = [(exp - timestamp).abs, 30].min
              
              if !!(response = recover_transaction(signatures, current_rpc_id, timestamp - offset))
                response = Hashie::Mash.new(response)
              end
            end
          end
          
          if response.nil?
            response = request(options)
            
            response = if response.nil?
              error "No response, retrying ...", method_name
            elsif !response.kind_of? Net::HTTPSuccess
              warning "Unexpected response (code: #{response.code}): #{response.inspect}, retrying ...", method_name, true
            else
              case response.code
              when '200'
                body = response.body
                response = JSON[body]
                
                if response['id'] != options[:id]
                  warning "Unexpected rpc_id (expected: #{options[:id]}, got: #{response['id']}), retrying ...", method_name, true
                elsif response.keys.include?('error')
                  handle_error(response, options, method_name, tries)
                else
                  Hashie::Mash.new(response)
                end
              when '400' then warning 'Code 400: Bad Request, retrying ...', method_name, true
              when '429' then warning 'Code 429: Too Many Requests, retrying ...', method_name, true
              when '502' then warning 'Code 502: Bad Gateway, retrying ...', method_name, true
              when '503' then warning 'Code 503: Service Unavailable, retrying ...', method_name, true
              when '504' then warning 'Code 504: Gateway Timeout, retrying ...', method_name, true
              else
                warning "Unknown code #{response.code}, retrying ...", method_name, true
                warning response
              end
            end
          end
        rescue Net::HTTP::Persistent::Error => e
          warning "Unable to perform request: #{e} :: #{!!e.cause ? "cause: #{e.cause.message}" : ''}, retrying ...", method_name, true
        rescue Errno::ECONNREFUSED => e
          warning 'Connection refused, retrying ...', method_name, true
        rescue Errno::EADDRNOTAVAIL => e
          warning 'Node not available, retrying ...', method_name, true
        rescue Errno::ECONNRESET => e
          warning "Connection Reset (#{e.message}), retrying ...", method_name, true
        rescue Net::ReadTimeout => e
          warning 'Node read timeout, retrying ...', method_name, true
        rescue Net::OpenTimeout => e
          warning 'Node timeout, retrying ...', method_name, true
        rescue RangeError => e
          warning 'Range Error, retrying ...', method_name, true
        rescue OpenSSL::SSL::SSLError => e
          warning "SSL Error (#{e.message}), retrying ...", method_name, true
        rescue SocketError => e
          warning "Socket Error (#{e.message}), retrying ...", method_name, true
        rescue JSON::ParserError => e
          warning "JSON Parse Error (#{e.message}), retrying ...", method_name, true
          response = nil
        rescue ApiError => e
          warning "ApiError (#{e.message}), retrying ...", method_name, true
        # rescue => e
        #   warning "Unknown exception from request, retrying ...", method_name, true
        #   warning e
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
    
    def block_api
      @block_api ||= self.class == BlockApi ? self : BlockApi.new(@api_options)
    end
    
    def rpc_id
      @rpc_id ||= 0
      @rpc_id = @rpc_id + 1
    end
    
    def uri
      @uri ||= URI.parse(@url)
    end
    
    def http_id
      @http_id ||= "radiator-#{Radiator::VERSION}-#{api_name}-#{SecureRandom.uuid}"
    end
    
    def http
      idempotent = api_name != :network_broadcast_api
        
      @http ||= if defined? Net::HTTP::Persistent::DEFAULT_POOL_SIZE
        Net::HTTP::Persistent.new(name: http_id, pool_size: @pool_size)
      else
        # net-http-persistent < 3.0
        Net::HTTP::Persistent.new(http_id)
      end
      
      @http.keep_alive = 30
      @http.read_timeout = 10
      @http.open_timeout = 10
      @http.idle_timeout = idempotent ? 10 : nil
      @http.max_requests = @max_requests
      @http.retry_change_requests = idempotent
      @http.verify_mode = @ssl_verify_mode
      @http.reuse_ssl_sessions = @reuse_ssl_sessions
      @http.ssl_version = @ssl_version
      
      @http
    end
    
    def post_request
      Net::HTTP::Post.new uri.request_uri, POST_HEADERS
    end
    
    def request(options)
      request = post_request
      request.body = JSON[options]
      http.request(uri, request)
    end
    
    def recover_transaction(signatures, expected_rpc_id, after)
      debug "Looking for signatures: #{signatures.map{|s| s[0..5]}} since: #{after}"
      
      count = 0
      start = Time.now.utc
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
        count += 1
        raise ApiError, "Race condition detected on remote node at: #{block_num}" if block.nil?
        
        timestamp = Time.parse(block.timestamp + 'Z')
        break if timestamp < after
        
        block.transactions.each_with_index do |tx, index|
          next unless ((tx['signatures'] || []) & signatures).any?
          
          debug "Found transaction #{count} block(s) ago; took #{(Time.now.utc - start)} seconds to scan."
          
          return {
            id: expected_rpc_id,
            recovered_by: http_id,
            result: {
              id: block.transaction_ids[index],
              block_num: block_num,
              trx_num: index,
              expired: false
            }
          }
        end
      end
      
      debug "Could not find transaction in #{count} block(s); took #{(Time.now.utc - start)} seconds to scan."
      
      return nil
    end
    
    def reset_failover
      @url = @preferred_url.dup
      @failover_urls = @preferred_failover_urls.dup
      warning "Failover reset, going back to #{@url} ..."
    end
    
    def pop_failover_url
      reset_failover if @failover_urls.none?
      
      until @failover_urls.none? || healthy?(url = @failover_urls.sample)
        @failover_urls.delete(url)
      end
      
      url || @url
    end
    
    def bump_failover
      @uri = nil
      @url = pop_failover_url
      warning "Failing over to #{@url} ..."
    end
    
    def flappy?
      !!@backoff_at && Time.now.utc - @backoff_at < 300
    end
    
    def drop_current_failover_url(prefix)
      if @preferred_failover_urls.size == 1
        warning "Node #{@url} appears to be misconfigured but no other node is available, retrying ...", prefix
      else
        warning "Removing misconfigured node from failover urls: #{@url}, retrying ...", prefix
        @preferred_failover_urls.delete(@url)
        @failover_urls.delete(@url)
      end
    end
   
    def handle_error(response, request_options, method_name, tries)
      parser = ErrorParser.new(response)
      _signatures, exp = extract_signatures(request_options)
      
      if (!!exp && exp < Time.now.utc) || tries > 2
        # Whatever the error was, it is already expired or tried too much.  No
        # need to try to recover.
        
        debug "Error code #{parser} but transaction already expired or too many tries, giving up (attempt: #{tries})."
      elsif parser.can_retry?
        drop_current_failover_url method_name if !!exp && parser.expiry?
        debug "Error code #{parser} (attempt: #{tries}), retrying ..."
        return nil
      end
      
      if !!parser.trx_id
        # Turns out, the ErrorParser found a transaction id.  It might come in
        # handy, so let's append this to the result along with the error.
        
        response[:result] = {
          id: parser.trx_id,
          block_num: -1,
          trx_num: -1,
          expired: false
        }
        
        if @recover_transactions_on_error
          begin
            # Node operators often disable this operation.
            api.get_transaction(parser.trx_id) do |tx|
              if !!tx
                response[:result][:block_num] = tx.block_num
                response[:result][:trx_num] = tx.transaction_num
                response[:recovered_by] = http_id
                response.delete('error') # no need for this, now
              end
            end
          rescue
            debug "Couldn't find block for trx_id: #{parser.trx_id}, giving up."
          end
        end
      end
      
      Hashie::Mash.new(response)
    end
    
    def healthy?(url)
      begin
        # Note, not all nodes support the /health uri.  But even if they don't,
        # they'll respond status code 200 OK, even if the body shows an error.
        
        # But if the node supports the /health uri, it will do additional
        # verifications on the block height.
        # See: https://github.com/steemit/steem/blob/master/contrib/healthcheck.sh
        
        # Also note, this check is done **without** net-http-persistent.
        
        !!open(url + HEALTH_URI)
      rescue => e
        error "Health check failure for #{url}: #{e.inspect}"
        sleep 0.2
        false
      end
    end
    
    def backoff
      shutdown
      bump_failover if flappy? || !healthy?(@url)
      @backoff_at ||= Time.now.utc
      @backoff_sleep ||= 0.01
      
      @backoff_sleep *= 2
      sleep @backoff_sleep
      
      if !!@backoff_at && Time.now.utc - @backoff_at > 300
        @backoff_at = nil 
        @backoff_sleep = nil
      end
    end
  end
end
