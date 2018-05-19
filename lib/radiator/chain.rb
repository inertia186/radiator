module Radiator
  # Examples ...
  # 
  # To vote on a post/comment:
  # 
  #     steem = Radiator::Chain.new(chain: :steem, account_name: 'your account name', wif: 'your wif')
  #     steem.vote!(10000, 'author', 'post-or-comment-permlink')
  # 
  # To post and vote in the same transaction:
  # 
  #     steem = Radiator::Chain.new(chain: :steem, account_name: 'your account name', wif: 'your wif')
  #     steem.post!(title: 'title of my post', body: 'body of my post', tags: ['tag'], self_upvote: 10000)
  #
  # To post and vote with declined payout:
  #
  #     steem = Radiator::Chain.new(chain: :steem, account_name: 'your account name', wif: 'your wif')
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
    include Mixins::ActsAsPoster
    include Mixins::ActsAsVoter
    include Mixins::ActsAsWallet
    
    VALID_OPTIONS = %w(
      chain account_name wif url failover_urls
    ).map(&:to_sym)
    VALID_OPTIONS.each { |option| attr_accessor option }
    
    def self.parse_slug(*args)
      args = [args].flatten
      
      if args.size == 1
        case args[0]
        when String then split_slug(args[0])
        when Hash then [args[0]['author'], args[0]['permlink']]
        end
      else
        args
      end
    end
    
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
      
      reset
    end
    
    # Find a specific block by block number.
    #
    # Example:
    #
    #     steem = Radiator::Chain.new(chain: :steem)
    #     block = steem.find_block(12345678)
    #     transactions = block.transactions
    #
    # @param block_number [Fixnum]
    # @return [Hash]
    def find_block(block_number)
      api.get_blocks(block_number).first
    end
    
    # Find a specific account by name.
    #
    # Example:
    #
    #     steem = Radiator::Chain.new(chain: :steem)
    #     ned = steem.find_account('ned')
    #     vesting_shares = ned.vesting_shares
    #
    # @param account_name [String] Name of the account to find.
    # @return [Hash]
    def find_account(account_name)
      api.get_accounts([account_name]) do |accounts, err|
        raise ChainError, ErrorParser.new(err) if !!err
        
        accounts[0]
      end
    end
    
    # Find a specific comment by author and permlink or slug.
    #
    # Example:
    #
    #     steem = Radiator::Chain.new(chain: :steem)
    #     comment = steem.find_comment('inertia', 'kinda-spooky') # by account, permlink
    #     active_votes = comment.active_votes
    #
    # ... or ...
    #
    #     comment = steem.find_comment('@inertia/kinda-spooky') # by slug
    #
    # @param args [String || Array<String>] Slug or author, permlink of comment.
    # @return [Hash]
    def find_comment(*args)
      author, permlink = Chain.parse_slug(args)
      
      api.get_content(author, permlink) do |comment, err|
        raise ChainError, ErrorParser.new(err) if !!err
        
        comment unless comment.id == 0
      end
    end
    
    # Current dynamic global properties, cached for 3 seconds.  This is useful
    # for reading properties without worrying about actually fetching it over
    # rpc more than needed.
    def properties
      @properties ||= nil
      
      if !!@properties && Time.now.utc - Time.parse(@properties.time + 'Z') > 3
        @properties = nil
      end
      
      return @properties if !!@properties
      
      api.get_dynamic_global_properties do |properties|
        @properties = properties
      end
    end
    
    def block_time
      Time.parse(properties.time + 'Z')
    end
    
    # Returns the current base (e.g. STEEM) price in the vest asset (e.g.
    # VESTS).
    #
    def base_per_mvest
      total_vesting_fund_steem = properties.total_vesting_fund_steem.to_f
      total_vesting_shares_mvest = properties.total_vesting_shares.to_f / 1e6
    
      total_vesting_fund_steem / total_vesting_shares_mvest
    end
    
    # Returns the current base (e.g. STEEM) price in the debt asset (e.g SBD).
    #
    def base_per_debt
      api.get_feed_history do |feed_history|
        current_median_history = feed_history.current_median_history
        base = current_median_history.base
        base = base.split(' ').first.to_f
        quote = current_median_history.quote
        quote = quote.split(' ').first.to_f
        
        (base / quote) * base_per_mvest
      end
    end
    
    # List of accounts followed by account.
    #
    # @param account_name String Name of the account.
    # @return [Array<String>]
    def followed_by(account_name)
      return [] if account_name.nil?
      
      followers = []
      count = -1

      until count == followers.size
        count = followers.size
        follow_api.get_followers(account: account_name, start: followers.last, type: 'blog', limit: 1000) do |follows, err|
          raise ChainError, ErrorParser.new(err) if !!err
          
          followers += follows.map(&:follower)
          followers = followers.uniq
        end
      end
      
      followers
    end
    
    # List of accounts following account.
    #
    # @param account_name String Name of the account.
    # @return [Array<String>]
    def following(account_name)
      return [] if account_name.nil?
      
      following = []
      count = -1

      until count == following.size
        count = following.size
        follow_api.get_following(account: account_name, start: following.last, type: 'blog', limit: 100) do |follows, err|
          raise ChainError, ErrorParser.new(err) if !!err
          
          following += follows.map(&:following)
          following = following.uniq
        end
      end

      following
    end
    
    # Clears out queued properties.
    def reset_properties
      @properties = nil
    end
    
    # Clears out queued operations.
    def reset_operations
      @operations = []
    end
    
    # Clears out all properties and operations.
    def reset
      reset_properties
      reset_operations
      
      @api = @block_api = @follow_api = nil
    end
    
    # Broadcast queued operations.
    #
    # @param auto_reset [boolean] clears operations no matter what, even if there's an error.
    def broadcast!(auto_reset = false)
      raise ChainError, "Required option: chain" if @chain.nil?
      raise ChainError, "Required option: account_name, wif" if @account_name.nil? || @wif.nil?
      
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
  private
    def self.split_slug(slug)
      slug = slug.split('@').last
      author = slug.split('/')[0]
      permlink = slug.split('/')[1..-1].join('/')
      permlink = permlink.split('#')[0]
      
      [author, permlink]
    end
    
    def build_options
      {
        chain: chain,
        wif: wif,
        url: url,
        failover_urls: failover_urls
      }
    end
    
    def api
      @api ||= Api.new(build_options)
    end
    
    def block_api
      @block_api ||= BlockApi.new(build_options)
    end
    
    def follow_api
      @follow_api ||= FollowApi.new(build_options)
    end
    
    def default_max_acepted_payout
      "1000000.000 #{default_debt_asset}"
    end
    
    def default_debt_asset
      case chain
      when :steem then ChainConfig::NETWORKS_STEEM_DEBT_ASSET
      when :test then ChainConfig::NETWORKS_TEST_DEBT_ASSET
      else; raise ChainError, "Unknown chain: #{chain}"
      end
    end
  end
end
