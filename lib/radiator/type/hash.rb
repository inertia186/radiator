module Radiator
  module Type
    class Hash < Serializer
      def initialize(value)
        super(:hash, true)
      end
      
      def to_bytes
        pakHash(@value)
      end
      
      def to_s
        @value.to_json
      end
    end
  end
end
