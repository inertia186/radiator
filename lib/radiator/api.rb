require 'uri'
require 'base64'
require 'hashie'
require 'hashie/logger'
require 'openssl'
require 'net/http/persistent'

module Radiator
  class Api
    def initialize(options = {})
      @user = options[:user]
      @password = options[:password]
      @url = options[:url] || 'https://steemd.steemit.com'
      @debug = !!options[:debug]
      @net_http_persistent_enabled = true
      @logger = options[:logger] || Radiator.logger
      
      Hashie.logger = @logger
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

      response = request(options)
      
      if !!response
        response = JSON[response.body]
        
        Hashie::Mash.new(response)
      end
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
      @http ||= Net::HTTP::Persistent.new "radiator-#{Radiator::VERSION}-#{self.class.name.downcase}"
    end
    
    def request(options)
      if !!@net_http_persistent_enabled
        begin
          request = Net::HTTP::Post.new uri.request_uri, 'Content-Type' => 'application/json'
          request.body = JSON[options]
          return http.request(uri, request)
        rescue Net::HTTP::Persistent::Error
          @net_http_persistent_enabled = false
        end
      end
        
      unless @net_http_persistent_enabled
        @http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new uri.request_uri, 'Content-Type' => 'application/json'
        request.body = JSON[options]
        @http.request(request)
      end
    end
  end
end
