# @deprecated Using Radiator::Type::Amount class provided is deprecated.  Please use: Hive::Type::Amount
module Radiator
  module Type
    class Amount < Hive::Type::Amount
      def initialize(options = {})
        unless defined? @@deprecated_warning_shown
          warn "[DEPRECATED] Using Radiator::Type::Amount class provided is deprecated.  Please use: Hive::Type::Amount"
          @@deprecated_warning_shown = true
          
          super(options.merge(chain: :hive))
        end
      end
    end
  end
end
