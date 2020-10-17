# @deprecated Using Radiator::Type::Amount class provided is deprecated.  Please use: Hive::Type::Amount
module Radiator
  module Type
    class Amount < Hive::Type::Amount
      def initialize(options = {})
        unless defined? @@deprecated_warning_shown
          warn "[DEPRECATED] Using Radiator::Type::Amount class provided is deprecated.  Please use: Hive::Type::Amount"
          @@deprecated_warning_shown = true
          
          super(options.merge(chain: :steem))
        end
      end
    end
  end
end

# Patch for legacy serializer.
class Hive::Type::Amount
  def to_bytes
    asset = case @asset
    when 'HBD' then 'SBD'
    when 'HIVE' then 'STEEM'
    else; @asset
    end
    
    asset = asset.ljust(7, "\x00")
    amount = (@amount.to_f * 10 ** @precision).round
    
    [amount].pack('q') +
    [@precision].pack('c') +
    asset
  end
end
