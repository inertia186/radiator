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
  # `Radiator::CondenserApi`.
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
    
    DEFAULT_STEEM_FAILOVER_URLS = [
      DEFAULT_STEEM_URL,
      'https://api.steemitstage.com',
      'https://appbasetest.timcliff.com',
      'https://api.steem.house',
      'https://seed.bitcoiner.me',
      'https://steemd.minnowsupportproject.org',
      'https://steemd.privex.io',
      'https://rpc.steemliberator.com',
      'https://rpc.curiesteem.com',
      'https://rpc.buildteam.io',
      'https://steemd.pevo.science',
      'https://rpc.steemviz.com',
      'https://steemd.steemgigs.org'
    ]
    
    # @private
    POST_HEADERS = {
      'Content-Type' => 'application/json',
      'User-Agent' => Radiator::AGENT_ID
    }
    
    # @private
    HEALTH_URI = '/health'
    
    def self.default_url(chain)
      case chain.to_sym
      when :steem then DEFAULT_STEEM_URL
      else; raise ApiError, "Unsupported chain: #{chain}"
      end
    end
    
    def self.default_failover_urls(chain)
      case chain.to_sym
      when :steem then DEFAULT_STEEM_FAILOVER_URLS
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
    # @option options [Boolean] :persist Enable or disable Persistent HTTP.  Using Persistent HTTP keeps the connection alive between API calls.  Default: `true`
    def initialize(options = {})
      @user = options[:user]
      @password = options[:password]
      @chain = options[:chain] || :steem
      @url = options[:url] || Api::default_url(@chain)
      @preferred_url = @url.dup
      @failover_urls = options[:failover_urls]
      @debug = !!options[:debug]
      @max_requests = options[:max_requests] || 30
      @ssl_verify_mode = options[:ssl_verify_mode] || OpenSSL::SSL::VERIFY_PEER
      @ssl_version = options[:ssl_version]

      @self_logger = false
      @logger = if options[:logger].nil?
        @self_logger = true
        Radiator.logger
      else
        options[:logger]
      end
      
      @self_hashie_logger = false
      @hashie_logger = if options[:hashie_logger].nil?
        @self_hashie_logger = true
        Logger.new(nil)
      else
        options[:hashie_logger]
      end
      
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
      
      @persist_error_count = 0
      @persist = if options.keys.include? :persist
        options[:persist]
      else
        true
      end
      
      @reuse_ssl_sessions = if options.keys.include? :reuse_ssl_sessions
        options[:reuse_ssl_sessions]
      else
        true
      end
      
      @use_condenser_namespace = if options.keys.include? :use_condenser_namespace
        options[:use_condenser_namespace]
      else
        true
      end
      
      if defined? Net::HTTP::Persistent::DEFAULT_POOL_SIZE
        @pool_size = options[:pool_size] || Net::HTTP::Persistent::DEFAULT_POOL_SIZE
      end
      
      Hashie.logger = @hashie_logger
      @method_names = nil
      @uri = nil
      @http_id = nil
      @http_memo = {}
      @api_options = options.dup.merge(chain: @chain)
      @api = nil
      @block_api = nil
      @backoff_at = nil
      @jussi_supported = []
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
          if use_condenser_namespace?
            yield api.get_block(i)
          else
            yield block_api.get_block(block_num: i).result, i
          end
        end
      else
        block_number.map do |i|
          if use_condenser_namespace?
            api.get_block(i)
          else
            block_api.get_block(block_num: i).result
          end
        end
      end
    end
    
    # Stops the persistant http connections.
    #
    def shutdown
      @uri = nil
      @http_id = nil
      @http_memo.each do |k|
        v = @http_memo.delete(k)
        if defined?(v.shutdown)
          debug "Shutting down instance #{k} (#{v})"
          v.shutdown
        end
      end
      @api.shutdown if !!@api && @api != self
      @api = nil
      @block_api.shutdown if !!@block_api && @block_api != self
      @block_api = nil
      
      if @self_logger
        if !!@logger && defined?(@logger.close)
          if defined?(@logger.closed?)
            @logger.close unless @logger.closed?
          end
        end
      end
      
      if @self_hashie_logger
        if !!@hashie_logger && defined?(@hashie_logger.close)
          if defined?(@hashie_logger.closed?)
            @hashie_logger.close unless @hashie_logger.closed?
          end
        end
      end
    end
    
    # @private
    def method_names
      return @method_names if !!@method_names
      return CondenserApi::METHOD_NAMES if api_name == :condenser_api

      @method_names = Radiator::Api.methods(api_name).map do |e|
        e['method'].to_sym
      end
    end
    
    # @private
    def api_name
      :condenser_api
    end
    
    # @private
    def respond_to_missing?(m, include_private = false)
      method_names.nil? ? false : method_names.include?(m.to_sym)
    end
    
    # @private
    def method_missing(m, *args, &block)
      super unless respond_to_missing?(m)
      
      current_rpc_id = rpc_id
      method_name = [api_name, m].join('.')
      response = nil
      options = if api_name == :condenser_api
        {
          jsonrpc: "2.0",
          method: method_name,
          params: args,
          id: current_rpc_id,
        }
      else
        rpc_args = if args.empty?
          {}
        else
          args.first
        end
        
        {
          jsonrpc: "2.0",
          method: method_name,
          params: rpc_args,
          id: current_rpc_id,
        }
      end
      
      tries = 0
      timestamp = Time.now.utc
      
      loop do
        tries += 1
        
        if tries > 5 && flappy? && !check_file_open?
          raise ApiError, 'PANIC: Out of file resources'
        end
        
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
              detect_jussi(response)
              
              case response.code
              when '200'
                body = response.body
                response = JSON[body]
                
                if response['id'] != options[:id]
                  debug_payload(options, body) if ENV['DEBUG'] == 'true'
                  
                  if !!response['id']
                    warning "Unexpected rpc_id (expected: #{options[:id]}, got: #{response['id']}), retrying ...", method_name, true
                  else
                    # The node has broken the jsonrpc spec.
                    warning "Node did not provide jsonrpc id (expected: #{options[:id]}, got: nothing), retrying ...", method_name, true
                  end
                  
                  if response.keys.include?('error')
                    handle_error(response, options, method_name, tries)
                  end
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
          if e.cause.class == Net::HTTPMethodNotAllowed
            warning 'Node upstream is misconfigured.'
            drop_current_failover_url method_name
          end
          
          @persist_error_count += 1
        rescue ConnectionPool::Error => e
          warning "Connection Pool Error (#{e.message}), retrying ...", method_name, true
        rescue Errno::ECONNREFUSED => e
          warning 'Connection refused, retrying ...', method_name, true
        rescue Errno::EADDRNOTAVAIL => e
          warning 'Node not available, retrying ...', method_name, true
        rescue Errno::ECONNRESET => e
          warning "Connection Reset (#{e.message}), retrying ...", method_name, true
        rescue Errno::EBUSY => e
          warning "Resource busy (#{e.message}), retrying ...", method_name, true
        rescue Errno::ENETDOWN => e
          warning "Network down (#{e.message}), retrying ...", method_name, true
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
          drop_current_failover_url method_name if tries > 5
          response = nil
        rescue ApiError => e
          warning "ApiError (#{e.message}), retrying ...", method_name, true
        # rescue => e
        #   warning "Unknown exception from request, retrying ...", method_name, true
        #   warning e
        end
        
        if !!response
          @persist_error_count = 0
          
          if !!block
            if api_name == :condenser_api
              return yield(response.result, response.error, response.id)
            else
              if defined?(response.result.size) && response.result.size == 0
                return yield(nil, response.error, response.id)
              elsif (
                defined?(response.result.size) && response.result.size == 1 &&
                defined?(response.result.values)
              )
                return yield(response.result.values.first, response.error, response.id)
              else
                return yield(response.result, response.error, response.id)
              end
            end
          else
            return response
          end
        end

        backoff
      end # loop
    end
    
    def inspect
      properties = %w(
        chain url backoff_at max_requests ssl_verify_mode ssl_version persist
        recover_transactions_on_error reuse_ssl_sessions pool_size
        use_condenser_namespace
      ).map do |prop|
        if !!(v = instance_variable_get("@#{prop}"))
          "@#{prop}=#{v}" 
        end
      end.compact.join(', ')
      
      "#<#{self.class.name} [#{properties}]>"
    end
    
    def stopped?
      http_active = if @http_memo.nil?
        false
      else
        @http_memo.values.map do |http|
          if defined?(http.active?)
            http.active?
          else
            false
          end
        end.include?(true)
      end
      
      @uri.nil? && @http_id.nil? && !http_active && @api.nil? && @block_api.nil?
    end
    
    def use_condenser_namespace?
      @use_condenser_namespace
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
    
    def self.apply_http_defaults(http, ssl_verify_mode)
      http.read_timeout = 10
      http.open_timeout = 10
      http.verify_mode = ssl_verify_mode
      http.ssl_timeout = 30 if defined? http.ssl_timeout
      http
    end
    
    def api_options
      @api_options.merge(failover_urls: @failover_urls, logger: @logger, hashie_logger: @hashie_logger)
    end
    
    def api
      @api ||= self.class == Api ? self : Api.new(api_options)
    end
    
    def block_api
      @block_api ||= self.class == BlockApi ? self : BlockApi.new(api_options)
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
      return @http_memo[http_id] if @http_memo.keys.include? http_id
      
      @http_memo[http_id] = if @persist && @persist_error_count < 10
        idempotent = api_name != :network_broadcast_api
        
        http = if defined? Net::HTTP::Persistent::DEFAULT_POOL_SIZE
          Net::HTTP::Persistent.new(name: http_id, pool_size: @pool_size)
        else
          # net-http-persistent < 3.0
          Net::HTTP::Persistent.new(http_id)
        end
        
        http.keep_alive = 30
        http.idle_timeout = idempotent ? 10 : nil
        http.max_requests = @max_requests
        http.retry_change_requests = idempotent
        http.reuse_ssl_sessions = @reuse_ssl_sessions
        
        http
      else
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http
      end
      
      Api::apply_http_defaults(@http_memo[http_id], @ssl_verify_mode)
    end
    
    def post_request
      Net::HTTP::Post.new uri.request_uri, POST_HEADERS
    end
    
    def request(options)
      request = post_request
      request.body = JSON[options]
      
      case http
      when Net::HTTP::Persistent then http.request(uri, request)
      when Net::HTTP then http.request(request)
      else; raise ApiError, "Unsuppored scheme: #{http.inspect}"
      end
    end
    
    def jussi_supported?(url = @url)
      @jussi_supported.include? url
    end
    
    def detect_jussi(response)
      return if jussi_supported?(@url)
      
      jussi_response_id = response['x-jussi-response-id']
      
      if !!jussi_response_id
        debug "Found a node that supports jussi: #{@url}"
        @jussi_supported << @url
      end
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
        unless defined? block.transaction_ids
          error "Blockchain does not provide transaction ids in blocks, giving up."
          return nil
        end
        
        count += 1
        raise ApiError, "Race condition detected on remote node at: #{block_num}" if block.nil?
        
        # TODO Some blockchains (like Golos) do not have transaction_ids.  In
        # the future, it would be better to decode the operation and signature
        # into the transaction id.
        # See: https://github.com/steemit/steem/issues/187
        # See: https://github.com/GolosChain/golos/issues/281
        unless defined? block.transaction_ids
          @recover_transactions_on_error = false
          return
        end
        
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
      
      url || (uri || @url).to_s
    end
    
    def bump_failover
      @uri = nil
      @url = pop_failover_url
      warning "Failing over to #{@url} ..."
    end
    
    def flappy?
      !!@backoff_at && Time.now.utc - @backoff_at < 300
    end
    
    # Note, this methods only removes the uri.to_s if present but it does not
    # call bump_failover, in order to avoid a race condition.
    def drop_current_failover_url(prefix)
      if @preferred_failover_urls.size == 1
        warning "Node #{uri} appears to be misconfigured but no other node is available, retrying ...", prefix
      else
        warning "Removing misconfigured node from failover urls: #{uri}, retrying ...", prefix
        @preferred_failover_urls.delete(uri.to_s)
        @failover_urls.delete(uri.to_s)
      end
    end
   
    def handle_error(response, request_options, method_name, tries)
      parser = ErrorParser.new(response)
      _signatures, exp = extract_signatures(request_options)
      
      if (!!exp && exp < Time.now.utc) || (tries > 2 && !parser.node_degraded?)
        # Whatever the error was, it is already expired or tried too much.  No
        # need to try to recover.
        
        debug "Error code #{parser} but transaction already expired or too many tries, giving up (attempt: #{tries})."
      elsif parser.can_retry?
        drop_current_failover_url method_name if !!exp && parser.expiry?
        drop_current_failover_url method_name if parser.node_degraded?
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
        
        response = open(url + HEALTH_URI)
        response = JSON[response.read]
        
        if !!response['error']
          if !!response['error']['data']
            if !!response['error']['data']['message']
              error "#{url} error: #{response['error']['data']['message']}"
            end
          elsif !!response['error']['message']
            error "#{url} error: #{response['error']['message']}"
          else
            error "#{url} error: #{response['error']}"
          end
          
          false
        elsif response['status'] == 'OK'
          true
        else
          error "#{url} status: #{response['status']}"
          
          false
        end
      rescue JSON::ParserError
        # No JSON, but also no HTTP error code, so we're OK.
        
        true
      rescue => e
        error "Health check failure for #{url}: #{e.inspect}"
        sleep 0.2
        false
      end
    end
    
    def check_file_open?
      File.exists?('.')
    rescue
      false
    end
    
    def debug_payload(request, response)
      request = JSON.pretty_generate(request)
      response = JSON.parse(response) rescue response
      response = JSON.pretty_generate(response) rescue response
      
      puts '=' * 80
      puts "Request:"
      puts request
      puts '=' * 80
      puts "Response:"
      puts response
      puts '=' * 80
    end
    
    def backoff
      shutdown
      bump_failover if flappy? || !healthy?(uri)
      @backoff_at ||= Time.now.utc
      @backoff_sleep ||= 0.01
      
      @backoff_sleep *= 2
      GC.start
      sleep @backoff_sleep
    ensure
      if !!@backoff_at && Time.now.utc - @backoff_at > 300
        @backoff_at = nil 
        @backoff_sleep = nil
      end
    end
    
    def self.finalize(logger, hashie_logger)
      proc {
        if !!logger && defined?(logger.close) && !logger.closed?
          logger.close
        end
        
        if !!hashie_logger && defined?(hashie_logger.close) && !hashie_logger.closed?
          hashie_logger.close
        end
      }
    end
  end
end
