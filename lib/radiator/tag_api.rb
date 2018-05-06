module Radiator
  class TagApi < Api
    def method_names
      @method_names ||= [
        :get_tags, # deprecated
        :get_trending_tags,
        :get_tags_used_by_author,
        :get_discussion,
        :get_content_replies,
        :get_post_discussions_by_payout,
        :get_comment_discussions_by_payout,
        :get_discussions_by_trending,
        :get_discussions_by_created,
        :get_discussions_by_active,
        :get_discussions_by_cashout,
        :get_discussions_by_votes,
        :get_discussions_by_children,
        :get_discussions_by_hot,
        :get_discussions_by_feed,
        :get_discussions_by_blog,
        :get_discussions_by_comments,
        :get_discussions_by_promoted,
        :get_replies_by_last_update,
        :get_discussions_by_author_before_date,
        :get_active_votes
      ].freeze
    end
    
    def api_name
      :tags_api
    end
  end
end