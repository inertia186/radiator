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
    INITIAL_TIMEOUT = 0.0200
    MAX_TIMEOUT = 80
    
    def initialize(options = {})
      @logger = options[:logger] || Radiator.logger
      @api = Api.new(options)
    end
    
    def method_names
      @method_names ||= [
        :head_block_number,
        :head_block_id,
        :time,
        :current_witness,
        :total_pow,
        :num_pow_witnesses,
        :virtual_supply,
        :current_supply,
        :confidential_supply,
        :current_sbd_supply,
        :confidential_sbd_supply,
        :total_vesting_fund_steem,
        :total_vesting_shares,
        :total_reward_fund_steem,
        :total_reward_shares2,
        :total_activity_fund_steem,
        :total_activity_fund_shares,
        :sbd_interest_rate,
        :average_block_size,
        :maximum_block_size,
        :current_aslot,
        :recent_slots_filled,
        :participation_count,
        :last_irreversible_block_num,
        :max_virtual_bandwidth,
        :current_reserve_ratio,
        :block_numbers,
        :blocks
      ].freeze
    end
    
    def method_params(method)
      case method
      when :block_numbers then {head_block_number: nil}
      when :blocks then {get_block: :head_block_number}
      else; nil
      end
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
        value = if (n = method_params(m)).nil?
          key_value = @api.get_dynamic_global_properties.result[m]
        else
          key = n.keys.first
          if !!n[key]
            r = @api.get_dynamic_global_properties.result
            key_value = param = r[n[key]]
            result = nil
            loop do
              response = @api.send(key, param)
              raise response.error.to_json if !!response.error
              result = response.result
              break if !!result
              @logger.warn "#{key}: #{param} result missing, retrying with timeout: #{@timeout || INITIAL_TIMEOUT} seconds"
              shutdown
              sleep timeout
            end
            @timeout = INITIAL_TIMEOUT
            result
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
    
    def timeout
      @timeout ||= INITIAL_TIMEOUT
      @timeout *= 2
      @timeout = INITIAL_TIMEOUT if @timeout > MAX_TIMEOUT
      @timeout
    end
    
    # Stops the persistant http connections.
    #
    def shutdown
      @api.shutdown
      http.shutdown
    end
  end
end