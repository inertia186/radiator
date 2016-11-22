module Radiator
  class ChainStatsApi < Api
    def method_names
      @method_names ||= {
        get_stats_for_time: 0,
        get_stats_for_interval: 1,
        get_lifetime_stats: 2
      }.freeze
    end
    
    def api_name
      :chain_stats_api
    end
  end
end
