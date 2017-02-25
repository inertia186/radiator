module Radiator
  # Radiator::Stream allows a live view of the STEEM blockchain.
  # 
  # All values returned by `get_dynamic_global_properties` can be streamed.
  # 
  # For example, if you want to know which witness is currently signing blocks,
  # use the following:
  # 
  #   stream = Radiator::Stream.new
  #   stream.current_witness do |witness|
  #     puts witness
  #   end
  class Stream < Api
    def initialize(options = {})
      @api = Api.new(options)
    end
    
    def method_names
      @method_names ||= {
        head_block_number: nil,
        head_block_id: nil,
        time: nil,
        current_witness: nil,
        total_pow: nil,
        num_pow_witnesses: nil,
        virtual_supply: nil,
        current_supply: nil,
        confidential_supply: nil,
        current_sbd_supply: nil,
        confidential_sbd_supply: nil,
        total_vesting_fund_steem: nil,
        total_vesting_shares: nil,
        total_reward_fund_steem: nil,
        total_reward_shares2: nil,
        total_activity_fund_steem: nil,
        total_activity_fund_shares: nil,
        sbd_interest_rate: nil,
        average_block_size: nil,
        maximum_block_size: nil,
        current_aslot: nil,
        recent_slots_filled: nil,
        participation_count: nil,
        last_irreversible_block_num: nil,
        max_virtual_bandwidth: nil,
        current_reserve_ratio: nil,
        
        block_numbers: {head_block_number: nil},
        blocks: {get_block: :head_block_number}
      }.freeze
    end
    
    # Returns the latest operations from the blockchain.
    # 
    # If symbol are passed, then only that operation is returned.  Expected
    # symbols are:
    #
    #   transfer_to_vesting
    #   withdraw_vesting
    #   interest
    #   transfer
    #   liquidity_reward
    #   author_reward
    #   curation_reward
    #   transfer_to_savings
    #   transfer_from_savings
    #   cancel_transfer_from_savings
    #   escrow_transfer
    #   escrow_approve
    #   escrow_dispute
    #   escrow_release
    #   comment
    #   limit_order_create
    #   limit_order_cancel
    #   fill_convert_request
    #   fill_order
    #   vote
    #   account_witness_vote
    #   account_witness_proxy
    #   account_create
    #   account_update
    #   witness_update
    #   pow
    #   custom
    #
    # @param type [symbol || Array<symbol>] the type(s) of operation, optional.
    # @param block the block to execute for each result, optional.
    # @return [Hash]
    def operations(type = nil, &block)
      transactions do |transaction|
        next if (_operations = transactions.map(&:operations)).none?
        ops = _operations.map do |operation|
          t = operation.first.first.to_sym
          if type == t
            operation.first.last
          elsif type.nil? || [type].flatten.include?(t)
            {t => operation.first.last}
          end
        end.reject(&:nil?)
        next if ops.none?
        
        return ops unless !!block
        
        ops.each do |op|
          yield op
        end
      end
    end
    
    # Returns the latest transactions from the blockchain.
    # 
    # @param block the block to execute for each result, optional.
    # @return [Hash]
    def transactions(&block)
      blocks do |b|
        next if b.nil?
        next if (_transactions = b.transactions).nil?
        return _transactions unless !!block
        
        _transactions.each.each do |transaction|
          yield transaction
        end
      end
    end
    
    def method_missing(m, *args, &block)
      super unless respond_to_missing?(m)
      
      @latest_values ||= []
      @latest_values.shift(5) if @latest_values.size > 20
      loop do
        value = if (n = method_names[m]).nil?
          key_value = @api.get_dynamic_global_properties.result[m]
        else
          key = n.keys.first
          if !!n[key]
            r = @api.get_dynamic_global_properties.result
            key_value = param = r[n[key]]
            @api.send(key, param).result
          else
            key_value = @api.get_dynamic_global_properties.result[key]
          end
        end
        unless @latest_values.include? key_value
          @latest_values << key_value
          if !!block
            yield value
          else
            return value
          end
        end
        sleep 0.0200
      end
    end
    
    # Stops the persistant http connections.
    #
    def shutdown
      @api.shutdown
      http.shutdown
    end
  end
end