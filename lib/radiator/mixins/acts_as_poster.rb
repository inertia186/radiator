module Radiator
  module Mixins
    module ActsAsPoster
      # Creates a post operation.
      #
      #     steem = Radiator::Chain.new(chain: :steem, account_name: 'your account name', wif: 'your wif')
      #     options = {
      #       title: 'This is my fancy post title.',
      #       body: 'This is my fancy post body.',
      #       tags: %w(thess are my fancy tags)
      #     }
      #     steem.post(options)
      #     steem.broadcast!
      #
      # @param options [Hash] options
      # @option options [String] :title Title of the post.
      # @option options [String] :body Body of the post.
      # @option options [Array<String>] :tags Tags of the post.
      # @option options [String] :permlink (automatic) Permlink of the post, defaults to formatted title.
      # @option options [String] :parent_permlink (automatic) Parent permlink of the post, defaults to first tag.
      # @option options [String] :parent_author (optional) Parent author of the post (only used if reply).
      # @option options [String] :max_accepted_payout (1000000.000 SBD) Maximum accepted payout, set to '0.000 SBD' to deline payout
      # @option options [Integer] :percent_steem_dollars (5000) Percent STEEM Dollars is used to set 50/50 or 100% STEEM Power
      # @option options [Integer] :allow_votes (true) Allow votes for this post.
      # @option options [Integer] :allow_curation_rewards (true) Allow curation rewards for this post.
      def post(options = {})
        tags = [options[:tags] || []].flatten
        title = options[:title].to_s
        permlink = options[:permlink] || title.downcase.gsub(/[^a-z0-9\-]+/, '-')
        parent_permlink = options[:parent_permlink] || tags[0]
        
        raise ChainError, 'At least one tag is required or set the parent_permlink directy.' if parent_permlink.nil?
        
        body = options[:body]
        parent_author = options[:parent_author] || ''
        max_accepted_payout = options[:max_accepted_payout] || default_max_acepted_payout
        percent_steem_dollars = options[:percent_steem_dollars]
        allow_votes = options[:allow_votes] || true
        allow_curation_rewards = options[:allow_curation_rewards] || true
        self_vote = options[:self_vote]
        
        tags.insert(0, parent_permlink)
        tags = tags.compact.uniq
        
        metadata = {
          app: Radiator::AGENT_ID
        }
        metadata[:tags] = tags if tags.any?
        
        @operations << {
          type: :comment,
          parent_permlink: parent_permlink,
          author: account_name,
          permlink: permlink,
          title: title,
          body: body,
          json_metadata: metadata.to_json,
          parent_author: parent_author
        }
        
        if (!!max_accepted_payout &&
            max_accepted_payout != default_max_acepted_payout
          ) || !!percent_steem_dollars || !allow_votes || !allow_curation_rewards
          @operations << {
            type: :comment_options,
            author: account_name,
            permlink: permlink,
            max_accepted_payout: max_accepted_payout,
            percent_steem_dollars: percent_steem_dollars,
            allow_votes: allow_votes,
            allow_curation_rewards: allow_curation_rewards,
            extensions: []
          }
        end
        
        vote(self_vote, account_name, permlink) if !!self_vote
        
        self
      end
      
      # Create a vote operation and broadcasts it right away.
      #
      #     steem = Radiator::Chain.new(chain: :steem, account_name: 'your account name', wif: 'your wif')
      #     options = {
      #       title: 'This is my fancy post title.',
      #       body: 'This is my fancy post body.',
      #       tags: %w(thess are my fancy tags)
      #     }
      #     steem.post!(options)
      #
      # @see post
      def post!(options = {}); post(options).broadcast!(true); end
      
      # Create a delete_comment operation.
      #
      # Examples:
      #
      #     steem = Radiator::Chain.new(chain: :steem, account_name: 'your account name', wif: 'your wif')
      #     steem.delete_comment('permlink')
      #     steem.broadcast!
      #
      # @param permlink
      def delete_comment(permlink)
        @operations << {
          type: :delete_comment,
          author: account_name,
          permlink: permlink
        }
        
        self
      end
      
      # Create a delete_comment operation and broadcasts it right away.
      #
      # Examples:
      #
      #     steem = Radiator::Chain.new(chain: :steem, account_name: 'your account name', wif: 'your wif')
      #     steem.delete_comment!('permlink')
      #
      # @see delete_comment
      def delete_comment!(permlink); delete_comment(permlink).broadcast!(true); end
    end
  end
end
