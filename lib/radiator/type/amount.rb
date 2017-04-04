module Radiator
  module Type
    
    # See: https://github.com/xeroc/piston-lib/blob/34a7525cee119ec9b24a99577ede2d54466fca0e/steembase/operations.py
    class Amount
      def initialize(value)
        @amount, @asset = value.strip.split(' ')
        @precision = case @asset
        when 'STEEM' then 3
        when 'VESTS' then 6
        when 'SBD' then 3
        when 'GOLOS' then 3
        when 'GESTS' then 6
        when 'GBG' then 3
        when 'CORE' then 3
        when 'CESTS' then 6
        when 'TEST' then 3
        else; raise TypeError, "Asset #{@asset} unknown."
        end
      end
      
      def to_bytes
        asset = @asset.ljust(7, "\x00")
        amount = (@amount.to_f * 10 ** @precision).round
        
        [amount].pack('q') +
        [@precision].pack('c') +
        asset
      end
      
      def to_s
        "#{@amount} #{@asset}"
      end
    end
  end
end
