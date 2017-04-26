module Radiator
  class BaseError < StandardError
    def initialize(error)
      @error = error
    end
    
    def to_s
      JSON[@error] rescue @error
    end
  end
end

module Radiator; class ApiError < BaseError; end; end
module Radiator; class StreamError < BaseError; end; end
module Radiator; class TypeError < BaseError; end; end
module Radiator; class OperationError < BaseError; end; end
module Radiator; class TransactionError < BaseError; end; end
