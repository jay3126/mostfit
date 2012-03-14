class LoanApplication
  include DataMapper::Resource
  include Constants::Status

  property :id,                  Serial
  property :status,              Enum.send('[]', *APPLICATION_STATUSES), :nullable => false, :default => Constants::Status::NEW_STATUS
  property :at_branch_id,        Integer, :nullable => false
  property :at_center_id,        Integer, :nullable => false
  property :created_by_staff_id, Integer, :nullable => false
  property :created_by_user_id,  Integer, :nullable => false
  property :created_at,          DateTime, :nullable => false, :default => DateTime.now
  property :amount,              Float

  has n, :client_verifications
  
  belongs_to :client

  # Returns the status of loan applications
  def get_status
    self.status
  end

  # Returns true if the loan application is approved, else false
  def is_approved?
    self.get_status == APPROVED_STATUS
  end

  # returns whether a client with the client_id is eligible for a new loan application
  #
  # @param [Integer] the client_id of the client in question
  # @return [Boolean] true/false value that tells whether the client in question is eligible for a new loan application
  def self.allow_new_loan_application?(client_id)
    client = Client.get(client_id)
    raise ArgumentError, "Invalid client id" unless client
    return true # this is dummy
    # the logic that will decide whether a said client is allowed to file a loan application
  end
  
  #tells whether the given Loan Application is pending verification or not
  def is_pending_verification?
    ClientVerification.is_cpv_complete?(self.id)
  end

  #returns all loan applications which are pending for CPV1 and/or CPV2
  def self.pending_verification(at_branch_id = nil, at_center_id = nil)
    predicates = {}
    predicates[:at_branch_id] = at_branch_id if at_branch_id
    predicates[:at_center_id] = at_center_id if at_center_id

    all(predicates).select {| l |l.is_pending_verification?}    
  end

end
