module Radiator
  class ChainStatsApi < Api
    def method_names
      @method_names ||= [
        :get_stats_for_time,
        :get_stats_for_interval,
        :get_lifetime_stats
      ].freeze
    end
    
    def api_name
      :chain_stats_api
    end
  end
end
