module Radiator
  # Examples ...
  # 
  # To vote on a post/comment:
  # 
  #     steem = Steem.new(account_name: 'your account name', wif: 'your wif')
  #     steem.vote!(10000, 'author', 'post-or-comment-permlink')
  # 
  # To post and vote in the same transaction:
  # 
  #     steem = Steem.new(account_name: 'your account name', wif: 'your wif')
  #     steem.post!(title: 'title of my post', body: 'body of my post', tags: ['tag'], self_upvote: 10000)
  #
  # To post and vote with declined payout:
  #
  #     steem = Steem.new(account_name: 'your account name', wif: 'your wif')
  #     
  #     options = {
  #       title: 'title of my post',
  #       body: 'body of my post',
  #       tags: ['tag'],
  #       self_upvote: 10000,
  #       percent_steem_dollars: 0
  #     }
  #     
  #     steem.post!(options)
  # 
  class Chain
    VALID_OPTIONS = %w(
      chain account_name wif
    ).map(&:to_sym)
    VALID_OPTIONS.each { |option| attr_accessor option }
    
    def initialize(options = {})
      options = options.dup
      options.each do |k, v|
        k = k.to_sym
        if VALID_OPTIONS.include?(k.to_sym)
          options.delete(k)
          send("#{k}=", v)
        end
      end
      
      @account_name ||= ENV['ACCOUNT_NAME']
      @wif ||= ENV['WIF']
      
      raise ChainError, "Required option: chain" if @chain.nil?
      raise ChainError, "Required option: account_name, wif" if @account_name.nil? || @wif.nil?
      
      reset
    end
    
    # Clears out queued operations.
    def reset
      @operations = []
    end
    
    # Broadcast queued operations.
    #
    # @param auto_reset [boolean] clears operations no matter what, even if there's an error.
    def broadcast!(auto_reset = false)
      begin
        transaction = Radiator::Transaction.new(build_options)
        transaction.operations = @operations
        response = transaction.process(true)
      rescue => e
        reset if auto_reset
        raise e
      end
      
      if !!response.result
        reset
        response
      else
        reset if auto_reset
        ErrorParser.new(response)
      end
    end
    
    # Create a vote operation.
    #
    # Examples:
    #
    #     steem = Steem.new(account_name: 'your account name', wif: 'your wif')
    #     steem.vote(10000, 'author', 'permlink')
    #     steem.broadcast!
    #
    # ... or ...
    #
    #     steem = Steem.new(account_name: 'your account name', wif: 'your wif')
    #     steem.vote(10000, '@author/permlink')
    #     steem.broadcast!
    #
    # @param weight [Integer] value between -10000 and 10000.
    # @param args [author, permlink || slug] pass either `author` and `permlink` or string containing both like `@author/permlink`.
    def vote(weight, *args)
      author, permlink = if args.size == 1
        author, permlink = parse_slug(args[0])
      else
        author, permlink = args
      end
      
      @operations << {
        type: :vote,
        voter: account_name,
        author: author,
        permlink: permlink,
        weight: weight
      }
      
      self
    end
    
    # Create a vote operation and broadcasts it right away.
    #
    # Examples:
    #
    #     steem = Steem.new(account_name: 'your account name', wif: 'your wif')
    #     steem.vote!(10000, 'author', 'permlink')
    #
    # ... or ...
    #
    #     steem = Steem.new(account_name: 'your account name', wif: 'your wif')
    #     steem.vote!(10000, '@author/permlink')
    #
    # @see vote
    def vote!(weight, *args); vote(weight, *args).broadcast!(true); end
    
    # Creates a post operation.
    #
    #     steem = Steem.new(account_name: 'your account name', wif: 'your wif')
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
    #     steem = Steem.new(account_name: 'your account name', wif: 'your wif')
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
    #     steem = Steem.new(account_name: 'your account name', wif: 'your wif')
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
    #     steem = Steem.new(account_name: 'your account name', wif: 'your wif')
    #     steem.delete_comment!('permlink')
    #
    # @see delete_comment
    def delete_comment!(permlink); delete_comment(permlink).broadcast!(true); end
    
    # Create a claim_reward_balance operation.
    #
    # Examples:
    #
    #     steem = Steem.new(account_name: 'your account name', wif: 'your wif')
    #     steem.claim_reward_balance(reward_sbd: '100.000 SBD')
    #     steem.broadcast!
    #
    # @param options [Hash] options
    # @option options [String] :reward_steem The amount of STEEM to claim, like: `100.000 STEEM`
    # @option options [String] :reward_sbd The amount of SBD to claim, like: `100.000 SBD`
    # @option options [String] :reward_vests The amount of VESTS to claim, like: `100.000000 VESTS`
    def claim_reward_balance(options)
      reward_steem = options[:reward_steem] || '0.000 STEEM'
      reward_sbd = options[:reward_sbd] || '0.000 SBD'
      reward_vests = options[:reward_vests] || '0.000000 VESTS'
      
      @operations << {
        type: :claim_reward_balance,
        account: account_name,
        reward_steem: reward_steem,
        reward_sbd: reward_sbd,
        reward_vests: reward_vests
      }
      
      self
    end
    
    # Create a claim_reward_balance operation and broadcasts it right away.
    #
    # Examples:
    #
    #     steem = Steem.new(account_name: 'your account name', wif: 'your wif')
    #     steem.claim_reward_balance!(reward_sbd: '100.000 SBD')
    #
    # @see claim_reward_balance
    def claim_reward_balance!(permlink); claim_reward_balance(permlink).broadcast!(true); end
    
    # Create a transfer operation.
    #
    #     steem = Steem.new(account_name: 'your account name', wif: 'your active wif')
    #     steem.transfer(amount: '1.000 SBD', to: 'account name', memo: 'this is a memo')
    #     steem.broadcast!
    #
    # @param options [Hash] options
    # @option options [String] :amount The amount to transfer, like: `100.000 STEEM`
    # @option options [String] :to The account receiving the transfer.
    # @option options [String] :memo ('') The memo for the transfer.
    def transfer(options = {})
      @operations << options.merge(type: :transfer, from: account_name)
      
      self
    end
    
    # Create a transfer operation and broadcasts it right away.
    #
    #     steem = Steem.new(account_name: 'your account name', wif: 'your wif')
    #     steem.transfer!(amount: '1.000 SBD', to: 'account name', memo: 'this is a memo')
    #
    # @see transfer
    def transfer!(options = {}); transfer(options).broadcast!(true); end
  private
    def build_options
      {
        chain: chain,
        wif: wif
      }
    end
    
    def parse_slug(slug)
      slug = slug.split('@').last
      author = slug.split('/')[0]
      [author, slug.split('/')[1..-1].join('/')]
    end
    
    def default_max_acepted_payout
      "1000000.000 #{default_debt_asset}"
    end
    
    def default_debt_asset
      case chain
      when :steem then 'SBD'
      when :golos then 'GBG'
      else; raise ChainError, "Unknown chain: #{chain}"
      end
    end
  end
end
