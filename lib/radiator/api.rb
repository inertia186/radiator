require 'uri'
require 'base64'
require 'hashie'
require 'openssl'
require 'net/http/persistent'

module Radiator
  class Api
    def initialize(options = {})
      @user = options[:user]
      @password = options[:password]
      @url = options[:url] || 'https://node.steem.ws:443'
      @debug = !!options[:debug]
      @net_http_persistent_enabled = true
    end
    
    def method_names
      @method_names ||= {
        cancel_all_subscriptions: 3,
        get_account_count: 35,
        get_account_history: 37,
        get_account_references: 32,
        get_account_votes: 50,
        get_accounts: 31,
        get_active_categories: 20,
        get_active_votes: 49,
        get_active_witnesses: 60,
        get_best_categories: 19,
        get_block: 16,
        get_block_header: 15,
        get_chain_properties: 24,
        get_config: 22,
        get_content: 51,
        get_content_replies: 52,
        get_conversion_requests: 36,
        get_current_median_history_price: 26,
        get_discussions_by_active: 8,
        get_discussions_by_author_before_date: 53,
        get_discussions_by_cashout: 9,
        get_discussions_by_children: 12,
        get_discussions_by_created: 7,
        get_discussions_by_feed: 14,
        get_discussions_by_hot: 13,
        get_discussions_by_payout: 10,
        get_discussions_by_trending: 5,
        get_discussions_by_trending30: 6,
        get_discussions_by_votes: 11,
        get_dynamic_global_properties: 23,
        get_feed_history: 25,
        get_hardfork_version: 28,
        get_key_references: 30,
        get_liquidity_queue: 42,
        get_miner_queue: 61,
        get_next_scheduled_hardfork: 29,
        get_open_orders: 41,
        get_order_book: 40,
        get_owner_history: 38,
        get_potential_signatures: 46,
        get_recent_categories: 21,
        get_recovery_request: 39,
        get_replies_by_last_update: 54,
        get_required_signatures: 45,
        get_state: 17,
        get_transaction: 44,
        get_transaction_hex: 43,
        get_trending_categories: 18,
        get_trending_tags: 4,
        get_witness_by_account: 56,
        get_witness_count: 59,
        get_witness_schedule: 27,
        get_witnesses: 55,
        get_witnesses_by_vote: 57,
        lookup_account_names: 33,
        lookup_accounts: 34,
        lookup_witness_accounts: 58,
        set_block_applied_callback: 2,
        set_pending_transaction_callback: 1,
        set_subscribe_callback: 0,
        verify_account_authority: 48,
        verify_authority: 47
      }.freeze
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
        yield get_blocks(block_number).result
      else
        get_blocks(block_number).result
      end
    end
    
    def find_account(id, &block)
      if !!block
        yield get_accounts([id]).result.first
      else
        get_accounts([id]).result.first
      end
    end
    
    def steem_per_mvest
      properties = get_dynamic_global_properties.result
      
      total_vesting_fund_steem = properties.total_vesting_fund_steem.to_f
      total_vesting_shares_mvest = properties.total_vesting_shares.to_f / 1e6
      
      total_vesting_fund_steem / total_vesting_shares_mvest
    end
    
    def respond_to_missing?(m, include_private = false)
      method_names.keys.include?(m.to_sym)
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
      http.shutdown
    end
  private
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
