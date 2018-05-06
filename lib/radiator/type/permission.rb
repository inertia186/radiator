module Radiator
  module Type
    
    # See: https://github.com/xeroc/piston-lib/blob/34a7525cee119ec9b24a99577ede2d54466fca0e/steembase/operations.py
    class Permission < Serializer
      def initialize(value)
        super(:permission, value)
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
