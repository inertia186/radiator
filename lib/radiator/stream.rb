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
  #
  # More importantly, full blocks, transactions, and operations can be streamed.
  class Stream < Api
    
    # @private
    INITIAL_TIMEOUT = 0.0200
    
    # @private
    MAX_TIMEOUT = 80
    
    # @private
    MAX_BLOCKS_PER_NODE = 100
    
    def initialize(options = {})
      @api_options = options.dup
      @logger = @api_options[:logger] || Radiator.logger
    end
    
    # Returns the latest operations from the blockchain.
    #
    #   stream = Radiator::Stream.new
    #   stream.operations do |op|
    #     puts op.to_json
    #   end
    # 
    # If symbol are passed, then only that operation is returned.  Expected
    # symbols are:
    #
    #   account_create
    #   account_create_with_delegation
    #   account_update
    #   account_witness_proxy
    #   account_witness_vote
    #   cancel_transfer_from_savings
    #   change_recovery_account
    #   claim_reward_balance
    #   comment
    #   comment_options
    #   convert
    #   custom
    #   custom_json
    #   decline_voting_rights
    #   delegate_vesting_shares
    #   delete_comment
    #   escrow_approve
    #   escrow_dispute
    #   escrow_release
    #   escrow_transfer
    #   feed_publish
    #   limit_order_cancel
    #   limit_order_create
    #   limit_order_create2
    #   pow
    #   pow2
    #   recover_account
    #   request_account_recovery
    #   set_withdraw_vesting_route
    #   transfer
    #   transfer_from_savings
    #   transfer_to_savings
    #   transfer_to_vesting
    #   vote
    #   withdraw_vesting
    #   witness_update
    #
    # For example, to stream only votes:
    #
    #   stream = Radiator::Stream.new
    #   stream.operations(:vote) do |vote|
    #     puts vote.to_json
    #   end
    #
    # You can also stream virtual operations:
    #
    #   stream = Radiator::Stream.new
    #   stream.operations(:author_reward) do |vop|
    #       puts "#{vop.author} got paid for #{vop.permlink}: #{[vop.sbd_payout, vop.steem_payout, vop.vesting_payout]}"
    #   end
    #
    # ... or multiple virtual operation types;
    #
    #   stream = Radiator::Stream.new
    #   stream.operations([:produer_reward, :author_reward]) do |vop|
    #     puts vop
    #   end
    #
    # ... or all types, inluding virtual operation types;
    #
    #   stream = Radiator::Stream.new
    #   stream.operations(nil, nil, :head, include_virtual: true) do |vop|
    #     puts vop
    #   end
    #
    # Expected virtual operation types:
    #
    #   author_reward
    #   curation_reward
    #   fill_convert_request
    #   fill_order
    #   fill_vesting_withdraw
    #   interest
    #   shutdown_witness
    #
    # @param type [symbol || Array<symbol>] the type(s) of operation, optional.
    # @param start starting block
    # @param mode we have the choice between
    #   * :head the last block
    #   * :irreversible the block that is confirmed by 2/3 of all block producers and is thus irreversible!
    # @param block the block to execute for each result, optional.
    # @param options [Hash] additional options
    # @option options [Boollean] :include_virtual Also stream virtual options.  Setting this true will impact performance.  Default: false.
    # @return [Hash]
    def operations(type = nil, start = nil, mode = :irreversible, options = {include_virtual: false}, &block)
      type = [type].flatten.compact.map(&:to_sym)
      include_virtual = !!options[:include_virtual]
      
      if virtual_op_type?(type)
        include_virtual = true
      end
      
      latest_block_number = -1
      
      transactions(start, mode) do |transaction, trx_id, block_number|
        virtual_ops_collected = latest_block_number == block_number
        latest_block_number = block_number
        
        ops = transaction.operations.map do |t, op|
          t = t.to_sym
          if type.size == 1 && type.first == t
            op
          elsif type.none? || type.include?(t)
            {t => op}
          end
        end.compact
        
        if include_virtual && !virtual_ops_collected
          api.get_ops_in_block(block_number, true) do |vops|
            vops.each do |vtx|
              next unless defined? vtx.op
              
              t = vtx.op.first.to_sym
              op = vtx.op.last
              if type.size == 1 && type.first == t
                ops << op
              elsif type.none? || type.include?(t)
                ops << {t => op}
              end
            end
          end
          
          virtual_ops_collected = true
        end
        
        next if ops.none?
        
        return ops unless !!block
        
        ops.each do |op|
          yield op, trx_id, block_number
        end
      end
    end
    
    # Returns the latest transactions from the blockchain.
    #
    #   stream = Radiator::Stream.new
    #   stream.transactions do |tx, trx_id|
    #     puts "[#{trx_id}] #{tx.to_json}"
    #   end
    #
    # @param start starting block
    # @param mode we have the choice between
    #   * :head the last block
    #   * :irreversible the block that is confirmed by 2/3 of all block producers and is thus irreversible!
    # @param block the block to execute for each result, optional.
    # @return [Hash]
    def transactions(start = nil, mode = :irreversible, &block)
      blocks(start, mode) do |b, block_number|
        next if (_transactions = b.transactions).nil?
        return _transactions unless !!block
        
        _transactions.each_with_index do |transaction, index|
          trx_id = if !!b['transaction_ids']
            b['transaction_ids'][index]
          end
          
          yield transaction, trx_id, block_number
        end
      end
    end
    
    # Returns the latest blocks from the blockchain.
    #
    #   stream = Radiator::Stream.new
    #   stream.blocks do |bk, num|
    #     puts "[#{num}] #{bk.to_json}"
    #   end
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
      latest_block_number = -1
      @api_options[:max_requests] = [max_blocks_per_node * 2, @api_options[:max_requests].to_i].max
      
      loop do
        catch :sequence do; begin
          head_block = api.get_dynamic_global_properties do |properties|
            if properties.head_block_number.nil?
              # This can happen if a reverse proxy is acting up.
              standby "Bad block sequence after height: #{latest_block_number}", {
                and: {throw: :sequence}
              }
            end
                
            case mode.to_sym
            when :head then properties.head_block_number
            when :irreversible then properties.last_irreversible_block_num
            else; raise StreamError, '"mode" has to be "head" or "irreversible"'
            end
          end
            
          if head_block == latest_block_number
            # This can when there's a delay in block production.
            sleep 0.5
            throw :sequence
          elsif head_block < latest_block_number
            # This can happen if a reverse proxy is acting up.
            standby "Invalid block sequence at height: #{head_block}", {
              and: {backoff: api, throw: :sequence}
            }
          end
          
          start ||= head_block
          range = (start..head_block)
          
          if range.size > 400
            # When the range is 400 blocks, the stream will be behind by about
            # 20 minutes.  Time to warn.
            standby "Stream behind by #{range.size} blocks (about #{(range.size * 3) / 60.0} minutes)."
          end
          
          [*range].each do |n|
            if (counter += 1) > max_blocks_per_node
              shutdown
              counter = 0
            end

            block_api.get_block(n) do |current_block, error|
              if current_block.nil?
                standby "Node responded with: empty block, retrying ...", {
                  and: {throw: :sequence}
                }
              elsif !!error
                standby "Node responded with: #{error.message || 'unknown error'}, retrying ...", {
                  error: error,
                  and: {throw: :sequence}
                }
              end
              
              latest_block_number = n
              return current_block, n if block.nil?
              yield current_block, n
            end
            
            start = head_block + 1
            sleep 3 / range.size
          end
        rescue StreamError; raise
        # rescue => e
        #   warning "Unknown streaming error: #{e.inspect}, retrying ...  "
        #   ap e
        #   redo
        end; end
      end
    end
    
    # Stops the persistant http connections.
    #
    def shutdown
      begin
        @api.shutdown
      rescue => e
        warning("Unable to shut down: #{e}")
      end
      
      @api = nil
    end
    
    # @private
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
    
    # @private
    def method_params(method)
      case method
      when :block_numbers then {head_block_number: nil}
      when :blocks then {get_block: :head_block_number}
      else; nil
      end
    end
  private
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
              warnning "#{key}: #{param} result missing, retrying with timeout: #{@timeout || INITIAL_TIMEOUT} seconds"
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
    
    def virtual_op_type?(type)
      type = [type].flatten.compact.map(&:to_sym)
      
      (Radiator::OperationTypes::TYPES.keys && type).any?
    end
    
    def standby(message, options = {})
      error = options[:error]
      secondary = options[:and] || {}
      backoff_api = secondary[:backoff]
      throwable = secondary[:throw]
      
      warning message
      
      ap error if !!error
      backoff_api.send :backoff if !!backoff_api
      throw throwable if !!throwable
    end
  end
end
