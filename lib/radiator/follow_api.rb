module Radiator
  class FollowApi < Api
    def method_names
      @method_names ||= {
        get_account_reputations: 4,
        get_feed: 3,
        get_feed_entries: 2,
        get_followers: 0,
        get_following: 1,
        get_follow_count: 5, # FIXME double-check these index values
        get_blog_entries: 6,
        get_blog: 7
      }.freeze
    end
    
    def api_name
      :follow_api
    end
  end
end