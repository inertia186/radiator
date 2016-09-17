module Radiator
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
    
    def operations(type = nil, &block)
      transactions do |transaction|
        next if (_operations = transactions.map(&:operations)).none?
        ops = _operations.map do |operation|
          if type.nil?
            {operation.first.first.to_sym => operation.first.last}
          elsif type == operation.first.first.to_sym
            operation.first.last
          end
        end.reject(&:nil?)
        next if ops.none?
        
        return ops unless !!block
        
        ops.each do |op|
          yield op
        end
      end
    end
    
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
        value = if (n = method_names[m]).nil?
          key_value = @api.get_dynamic_global_properties.result[m]
        else
          key = n.keys.first
          if !!n[key]
            key_value = param = @api.get_dynamic_global_properties.result[n[key]]
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
  end
end