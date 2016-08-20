module Radiator
  class FollowApi < Api
    def method_names
      @method_names ||= {
        get_account_reputations: 4,
        get_feed: 3,
        get_feed_entries: 2,
        get_followers: 0,
        get_following: 1
      }.freeze
    end
    
    def api_name
      :follow_api
    end
  end
end