module Radiator
  module Utils
    module Exceptions
      class RadiatorError < StandardError
        attr_reader :message
        def initialize(message)
          @message = message
        end
      end
      
      class RadiatorArgumentError < RadiatorError
      end
    end
  end
end
