module Radiator
  class MarketHistoryApi < Api
    def method_names
      @method_names ||= {
        get_market_history: 5,
        get_market_history_buckets: 6,
        get_order_book: 2,
        get_recent_trades: 4,
        get_ticker: 0,
        get_trade_history: 3,
        get_volume: 1
      }.freeze
    end
    
    def api_name
      :market_history_api
    end
  end
end