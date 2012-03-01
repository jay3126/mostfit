module Constants
  # All constants for use in the application should be namespaces under further modules under this module

  module Status
    #All constants that are related to statuses, handle with care

    CREATED = :created

    REQUEST_STATUSES = [CREATED, :sent, :response_received]
    
  end

end