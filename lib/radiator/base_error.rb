module Radiator
  class BaseError < StandardError
    def initialize(error, cause = nil)
      @error = error
      @cause = cause
    end
    
    def to_s
      if !!@cause
        JSON[error: @error, cause: @cause] rescue {error: @error, cause: @cause}.to_s
      else
        JSON[@error] rescue @error
      end
    end
  end
end

module Radiator; class ApiError < BaseError; end; end
module Radiator; class StreamError < BaseError; end; end
module Radiator; class TypeError < BaseError; end; end
module Radiator; class OperationError < BaseError; end; end
module Radiator; class TransactionError < BaseError; end; end
module Radiator; class ChainError < BaseError; end; end
