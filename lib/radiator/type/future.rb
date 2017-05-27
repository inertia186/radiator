module Radiator
  module Type
    
    # See: https://github.com/xeroc/piston-lib/blob/34a7525cee119ec9b24a99577ede2d54466fca0e/steembase/operations.py
    class Future < Serializer
      def initialize(value)
        super(:future, true)
      end
      
      def to_bytes
        [1].pack('U')
      end
      
      def to_s
      end
    end
  end
end
