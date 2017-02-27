module Radiator
  class MarketHistoryApi < Api
    def method_names
      @method_names ||= [
        :get_market_history,
        :get_market_history_buckets,
        :get_order_book,
        :get_recent_trades,
        :get_ticker,
        :get_trade_history,
        :get_volume
      ].freeze
    end
    
    def api_name
      :market_history_api
    end
  end
end