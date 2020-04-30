module Radiator
  module Type
    class Price < Serializer
      attr_reader :base, :quote, :chain

      def initialize(value, chain)
        super(:price, value)

        @chain = chain
        @base = Amount.new(value[:base], chain)
        @quote = Amount.new(value[:quote], chain)
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

      ##
      # the actual conversion rate between core and
      # dept.
      #
      def to_f
        return @base.amount.to_f / @quote.amount.to_f
      end
    end
  end
end
