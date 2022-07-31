module Radiator
  module SSC
    class BaseSteemSmartContractRPC
      # @private
      POST_HEADERS = {
        'Content-Type' => 'application/json',
        'User-Agent' => Radiator::AGENT_ID
      }
      
      MAX_BACKOFF = 60.0
      
      def initialize(options = {})
        @root_url = options[:root_url] || 'https://api.steem-engine.net/rpc'
        
        @self_hashie_logger = false
        @hashie_logger = if options[:hashie_logger].nil?
          @self_hashie_logger = true
          Logger.new(nil)
        else
          options[:hashie_logger]
        end
        
        unless @hashie_logger.respond_to? :warn
          @hashie_logger = Logger.new(@hashie_logger)
        end
        
        @reuse_ssl_sessions = if options.keys.include? :reuse_ssl_sessions
          options[:reuse_ssl_sessions]
        else
          true
        end
        
        @persist = if options[:persist].nil?
          true
        else
          options[:persist]
        end
        
        if defined? Net::HTTP::Persistent::DEFAULT_POOL_SIZE
          @pool_size = options[:pool_size] || Net::HTTP::Persistent::DEFAULT_POOL_SIZE
        end
        
        Hashie.logger = @hashie_logger
        @uri = nil
        @http_id = nil
        @http = nil
        @max_requests = options[:max_requests] || 30
      end
      
      # Stops the persistant http connections.
      #
      def shutdown
        @uri = nil
        @http_id = nil
        @http = nil
      end
    protected
      def rpc_id
        @rpc_id ||= 0
        @rpc_id = @rpc_id + 1
      end
      
      def uri
        @uri ||= URI.parse(@url)
      end
      
      def http_id
        @http_id ||= "radiator-#{Radiator::VERSION}-ssc-blockchain-#{SecureRandom.uuid}"
      end
      
      def http
        @http ||= if persist?
          if defined? Net::HTTP::Persistent::DEFAULT_POOL_SIZE
            Net::HTTP::Persistent.new(name: http_id, pool_size: @pool_size).tap do |http|
              http.keep_alive = 30
              http.idle_timeout = 10
              http.max_requests = @max_requests
              http.retry_change_requests = true if defined? http.retry_change_requests
              http.reuse_ssl_sessions = @reuse_ssl_sessions
            end
          else
            # net-http-persistent < 3.0
            Net::HTTP::Persistent.new(http_id) do |http|
              http = Net::HTTP.new(uri.host, uri.port)
              http.use_ssl = uri.scheme == 'https'
            end
          end
        else
          Net::HTTP.new(uri.host, uri.port).tap do |http|
            http.use_ssl = uri.scheme == 'https'
          end
        end
      end
      
      def post_request
        Net::HTTP::Post.new uri.request_uri, POST_HEADERS
      end
      
      def request(options)
        request = post_request
        skip_health_check = options.delete(:skip_health_check)
        request.body = JSON[options.merge(jsonrpc: '2.0', id: rpc_id)]
        
        unless skip_health_check
          unless healthy?
            @backoff ||= 0.1
            
            backoff = @backoff
            
            if !!backoff
              raise "Too many failures on #{url}" if backoff >= MAX_BACKOFF
              
              backoff *= backoff
              @backoff = backoff
              sleep backoff
            end
          end
          
          @backoff = nil
        end
        
        response = case http
        when Net::HTTP::Persistent then http.request(uri, request)
        when Net::HTTP then http.request(request)
        else; raise ApiError, "Unsuppored scheme: #{http.inspect}"
        end
        
        response = Hashie::Mash.new(JSON[response.body])
        
        if !!(error = response.error)
          raise ApiError, "Error #{error.code}: #{error.message}"
        end
        
        response.result
      end
      
      def healthy?
        warn("Health check not defined for: #{uri}")
        true
      end
      
      def persist?
        !!@persist
      end
    end
  end
end
