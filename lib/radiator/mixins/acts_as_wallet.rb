module Radiator
  module Mixins
    module ActsAsWallet
      # Create a claim_reward_balance operation.
      #
      # Examples:
      #
      #     steem = Radiator::Chain.new(chain: :steem, account_name: 'your account name', wif: 'your wif')
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
      #     steem = Radiator::Chain.new(chain: :steem, account_name: 'your account name', wif: 'your wif')
      #     steem.claim_reward_balance!(reward_sbd: '100.000 SBD')
      #
      # @see claim_reward_balance
      def claim_reward_balance!(permlink); claim_reward_balance(permlink).broadcast!(true); end
      
      # Create a transfer operation.
      #
      #     steem = Radiator::Chain.new(chain: :steem, account_name: 'your account name', wif: 'your active wif')
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
      #     steem = Radiator::Chain.new(chain: :steem, account_name: 'your account name', wif: 'your wif')
      #     steem.transfer!(amount: '1.000 SBD', to: 'account name', memo: 'this is a memo')
      #
      # @see transfer
      def transfer!(options = {}); transfer(options).broadcast!(true); end
    end
  end
end
