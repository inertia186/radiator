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
    MAX_BLOCKS_PER_NODE = 100
    
    def initialize(options = {})
      @api_options = options
      @logger = @api_options[:logger] || Radiator.logger
    end
    
    def api
      @api ||= Api.new(@api_options)
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
    # @param start starting block
    # @param mode we have the choice between
    #   * :head the last block
    #   * :irreversible the block that is confirmed by 2/3 of all block producers and is thus irreversible!
    # @param block the block to execute for each result, optional.
    # @return [Hash]
    def operations(type = nil, start = nil, mode = :irreversible, &block)
      transactions(start, mode) do |transaction|
        ops = transaction.operations.map do |t, op|
          t = t.to_sym
          if type == t
            op
          elsif type.nil? || [type].flatten.include?(t)
            {t => op}
          end
        end.compact
        
        next if ops.none?
        
        return ops unless !!block
        
        ops.each do |op|
          yield op
        end
      end
    end
    
    # Returns the latest transactions from the blockchain.
    # 
    # @param start starting block
    # @param mode we have the choice between
    #   * :head the last block
    #   * :irreversible the block that is confirmed by 2/3 of all block producers and is thus irreversible!
    # @param block the block to execute for each result, optional.
    # @return [Hash]
    def transactions(start = nil, mode = :irreversible, &block)
      blocks(start, mode) do |b|
        next if (_transactions = b.transactions).nil?
        return _transactions unless !!block
        
        _transactions.each.each do |transaction|
          yield transaction
        end
      end
    end
    
    # Returns the latest blocks from the blockchain.
    # 
    # @param start starting block
    # @param mode we have the choice between
    #   * :head the last block
    #   * :irreversible the block that is confirmed by 2/3 of all block producers and is thus irreversible!
    #   * :max_blocks_per_node the number of blocks to read before trying a new node
    # @param block the block to execute for each result, optional.
    # @return [Hash]
    def blocks(start = nil, mode = :irreversible, max_blocks_per_node = MAX_BLOCKS_PER_NODE, &block)
      counter = 0
      
      if start.nil?
        properties = api.get_dynamic_global_properties.result
        start = case mode.to_sym
        when :head then properties.head_block_number
        when :irreversible then properties.last_irreversible_block_num
        else; raise StreamError, '"mode" has to be "head" or "irreversible"'
        end
      end
      
      loop do
        properties = api.get_dynamic_global_properties.result
        
        head_block = case mode.to_sym
        when :head then properties.head_block_number
        when :irreversible then properties.last_irreversible_block_num
        else; raise StreamError, '"mode" has to be "head" or "irreversible"'
        end
        
        [*(start..(head_block))].each do |n|
          if (counter += 1) > max_blocks_per_node
            shutdown
            counter = 0
          end

          response = api.send(:get_block, n)
          raise StreamError, JSON[response.error] if !!response.error
          result = response.result
        
          if !!block
            yield result
          else
            return result
          end
        end
        
        start = head_block + 1
        sleep 3
      end
    end
    
    def method_missing(m, *args, &block)
      super unless respond_to_missing?(m)
      
      @latest_values ||= []
      @latest_values.shift(5) if @latest_values.size > 20
      loop do
        value = if (n = method_params(m)).nil?
          key_value = api.get_dynamic_global_properties.result[m]
        else
          key = n.keys.first
          if !!n[key]
            r = api.get_dynamic_global_properties.result
            key_value = param = r[n[key]]
            result = nil
            loop do
              response = api.send(key, param)
              raise StreamError, JSON[response.error] if !!response.error
              result = response.result
              break if !!result
              @logger.warn "#{key}: #{param} result missing, retrying with timeout: #{@timeout || INITIAL_TIMEOUT} seconds"
              shutdown
              sleep timeout
            end
            @timeout = INITIAL_TIMEOUT
            result
          else
            key_value = api.get_dynamic_global_properties.result[key]
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
      begin
        @api.shutdown
      rescue => e
        @logger.warn("Unable to shut down: #{e}")
      end
      
      @api = nil
    end
  end
end