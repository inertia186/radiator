module Radiator
  module Type
  
    # See: https://github.com/xeroc/piston-lib/blob/34a7525cee119ec9b24a99577ede2d54466fca0e/steembase/operations.py
    class PublicKey
      def initialize()
        raise NotImplementedError, 'stub'
      end
      
      def to_bytes
      end
      
      def to_s
      end
    end
  end
end
