module Errors

  # Raised when there is an error at the persistence layer
  class DataError < StandardError; end

  # Raised when there is a business validation that is violated
  class BusinessValidationError < StandardError; end

  # Raised when an instance does not support a particular operation
  class OperationNotSupportedError < StandardError; end

  # Raised when there is an issue due to a temporary or permanent problem with expected configuration
  class InvalidConfigurationError < StandardError; end
    
end
