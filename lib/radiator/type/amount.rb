module Radiator
  module Type
    
    # See: https://github.com/xeroc/piston-lib/blob/34a7525cee119ec9b24a99577ede2d54466fca0e/steembase/operations.py
    class Amount < Serializer
      attr_reader :amount, :precision, :nai, :asset
      
      def initialize(value)
        case value
        when ::Radiator::Type::Amount
          super(:amount, value.to_s)

          @amount    = value.amount
          @precision = value.precision
          @nai       = value.nai
          @asset     = value.asset
        when ::Array
          super(:amount, value)

          a, @precision, @nai = value
          @asset = case @nai
          when '@@000000013' then 'SBD'
          when '@@000000021' then 'STEEM'
          when '@@000000037' then 'VESTS'
          else; raise TypeError, "Asset #{@asset} unknown."
          end
          @amount = "%.#{@precision}f" % (a.to_f / 10 ** @precision)
        else
          super(:amount, value)

          @amount, @asset = value.strip.split(' ')
          @precision = case @asset
          when 'STEEM' then 3
          when 'VESTS' then 6
          when 'SBD' then 3
          when 'CORE' then 3
          when 'CESTS' then 6
          when 'TEST' then 3
          else; raise TypeError, "Asset #{@asset} unknown."
          end
        end
      end
      
      def to_bytes
        asset = @asset.ljust(7, "\x00")
        amount = (@amount.to_f * 10 ** @precision).round
        
        [amount].pack('q') +
        [@precision].pack('c') +
        asset
      end
      
      def to_a
        case @asset
        when 'STEEM' then [(@amount.to_f * 1000).to_i.to_s, 3, '@@000000021']
        when 'VESTS' then [(@amount.to_f * 1000000).to_i.to_s, 6, '@@000000037']
        when 'SBD' then [(@amount.to_f * 1000).to_i.to_s, 3, '@@000000013']
        else; raise TypeError, "Asset #{@asset} unknown."
        end
      end
      
      def to_s
        "#{@amount} #{@asset}"
      end
    end
  end
end
