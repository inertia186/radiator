module Radiator
  class Bridge < Api
    def method_names
      @method_names ||= [
        :normalize_post,
        :get_post_header,
        :get_discussion,
        :get_post,
        :get_account_posts,
        :get_ranked_posts,
        :get_profile,
        :get_trending_topics,
        :get_relationship_between_accounts,
        :post_notifications,
        :account_notifications,
        :unread_notifications,
        :get_payout_stats,
        :get_community,
        :get_community_context,
        :list_communities,
        :list_pop_communities,
        :list_community_roles,
        :list_subscribers,
        :list_all_subscriptions
      ].freeze
    end
    
    def api_name
      :bridge
    end
    
    def healthy?(_); true; end
  end
end
