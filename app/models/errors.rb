module Errors

  # Raised when there is an error at the persistence layer
  class DataError < StandardError; end

  # Raised when the application cannot locate an item in storage that is expected to be there
  class DataMissingError < StandardError; end

  # Raised when there is a business validation that is violated
  class BusinessValidationError < StandardError; end

  # Raised when an instance does not support a particular operation
  class OperationNotSupportedError < StandardError; end

  # Raised when there is an issue due to a temporary or permanent problem with expected configuration
  class InvalidConfigurationError < StandardError; end

  # Raised when the object is not completely initialised yet, such as a loan that does not yet have a loan schedule
  class InitialisationNotCompleteError < StandardError; end

  # Raised when an attempt is made to set the state on an object to one that is not permitted
  class InvalidStateChangeError < StandardError; end

  #raised when checklist is called with target_entity_name/type/id blank
  class Merb::ChecklisterSlice::ChecklistsHelper::TargetEntityNotFoundException < StandardError;end

  #raised when checklist is called with staff name/id blank.
  class Merb::ChecklisterSlice::ChecklistsHelper::StaffNotFoundException < StandardError;end
    
end
