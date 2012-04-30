module Errors

  # Raised when there is an error at the persistence layer
  class DataError < StandardError; end

  # Raised when there is a business validation that is violated
  class BusinessValidationError < StandardError; end
    
end
