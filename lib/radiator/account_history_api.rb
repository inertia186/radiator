module Radiator
  class AccountHistoryApi < Api
    def method_names
      @method_names ||= [
        :get_account_history,
        :get_ops_in_block,
        :get_transaction
      ].freeze
    end
    
    def api_name
      :account_history_api
    end
  end
end