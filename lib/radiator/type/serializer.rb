module Radiator
  module Type
    class Serializer
      include Radiator::Utils
      
      def initialize(key, value)
        @key = key
        @value = value
      end
    end
  end
end
