module Radiator
  module Type
  
    # See: https://github.com/xeroc/piston-lib/blob/34a7525cee119ec9b24a99577ede2d54466fca0e/steembase/operations.py
    class Uint32 < Serializer
      def initialize(value)
        super(:u_int_32, value.to_i)
      end
      
      def to_bytes
        [@value].pack('L')
      end
      
      def to_s
        @value.to_s
      end
    end
  end
end
