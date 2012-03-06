class ClientVerification
  include DataMapper::Resource
  include Constants::Verification

  property :id,                   Serial
  property :verification_type,    Enum.send('[]', *CLIENT_VERIFICATION_TYPES), :nullable => false
  property :verified_by_staff_id, Integer, :nullable => false
  property :verification_status,  Enum.send('[]', *CLIENT_VERIFICATION_STATUSES), :nullable => false, :default => NOT_VERIFIED
  property :updated_on,           Date, :nullable => false
  property :created_by_user_id,   Integer, :nullable => false
  property :updated_by_user_id,   Integer, :nullable => false
  
  belongs_to :loan_application, :nullable => false

  # Gets verification status
  def get_status
    self.verification_status
  end

  # Sets verification status
  def set_status(status, on_date, by_staff_id, by_user_id)
    self.verification_status = status
    self.updated_on = on_date
    self.verified_by_staff_id = by_staff_id
    set_updated_by(by_user_id)
  end

  private

  # Sets the user id that either created or updated this instance
  def set_updated_by(user_id)
    self.created_by_user_id.nil? ? (self.created_by_user_id = user_id) : (self.updated_by_user_id = user_id)
  end

end
