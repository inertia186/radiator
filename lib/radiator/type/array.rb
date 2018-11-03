module Radiator
  module Type
    class Array < Serializer
      def initialize(value)
        super(:array, true)
      end
      
      def to_bytes
        pakArr(@value)
      end
      
      def to_s
        @value.to_json
      end
    end
  end
end
