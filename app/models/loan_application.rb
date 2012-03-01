class LoanApplication
  include DataMapper::Resource
  include Constants::Status

  property :id,     Serial
  property :status, Enum.send('[]', *APPLICATION_STATUSES), :nullable => false, :default => NEW_STATUS

  # Returns the status of loan applications
  def get_status
    self.status
  end

  # Returns true if the loan application is approved, else false
  def is_approved?
    self.get_status == APPROVED_STATUS
  end

end
