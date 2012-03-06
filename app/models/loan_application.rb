class LoanApplication
  include DataMapper::Resource
  include Constants::Status

  property :id,                  Serial
  property :status,              Enum.send('[]', *APPLICATION_STATUSES), :nullable => false, :default => NEW_STATUS
  property :created_by_staff_id, Integer, :nullable => false
  property :created_by_user_id,  Integer, :nullable => false
  property :created_at,          DateTime, :nullable => false, :default => DateTime.now

  has n, :client_verifications

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

end
