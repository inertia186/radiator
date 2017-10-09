module Radiator
  class CondenserApi < Api
    def method_names
      @method_names ||= [
        :get_state,
        :get_next_scheduled_hardfork,
        :get_reward_fund,
        :get_accounts,
        :lookup_account_names,
        :lookup_accounts,
        :get_account_count,
        :get_savings_withdraw_to,
        :get_witnesses,
        :get_witness_count,
        :get_open_orders,
        :get_account_votes,
        :lookup_witness_accounts
      ].freeze
    end
    
    def api_name
      :condenser_api
    end
  end
end
