require 'uri'
require 'base64'
require 'hashie'

module Radiator
  class Api
    def initialize(options = {})
      @user = options[:user]
      @password = options[:password]
      @url = options[:url] || 'https://this.piston.rocks:443'
      @debug = !!options[:debug]
    end
    
    DEFAULT_TIMEOUT = 60 * 60 * 1
    
    VALID_ACTIONS = {
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
    
    def respond_to_missing?(m, include_private = false)
      VALID_ACTIONS.keys.include?(m.to_sym)
    end
    
    def method_missing(m, *args, &block)
      super unless respond_to_missing?(m)
      
      options = {method: m, id: 1}
      options[:params] = args if !!args
      
      response = RestClient.post(@url, JSON[options], timeout: DEFAULT_TIMEOUT)
      response = JSON[response]
      
      Hashie::Mash.new(response)
    end
    
    def self.instance=(instance)
      @@instance = instance
    end

    def self.instance
      @@instance ||= Radiator::Api.new
    end
  end
end
