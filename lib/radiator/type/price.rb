module Radiator
  module Type
    class Price < Serializer
      
      def initialize(value)
        super(:price, value)
        
        @base = Hive::Type::Amount.new(@value[:base])
        @quote = Hive::Type::Amount.new(@value[:quote])
      end
      
      def to_bytes
        @base.to_bytes + @quote.to_bytes
      end
      
      def to_h
        {@key => {base: @base, quote: @quote}}
      end
      
      def to_s
        to_h.to_json
      end
    end
  end
end
