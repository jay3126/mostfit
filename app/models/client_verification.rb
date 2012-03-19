class ClientVerification
  include DataMapper::Resource
  include Constants::Verification

  property :loan_application_id,  Integer, :nullable => false, :key => true, :index => true
  property :verification_type,    Enum.send('[]', *CLIENT_VERIFICATION_TYPES), :nullable => false, :key => true, :index => true
  property :verification_status,  Enum.send('[]', *CLIENT_VERIFICATION_STATUSES), :nullable => false, :default => NOT_VERIFIED, :key => true, :index => true
  property :verified_by_staff_id, Integer, :nullable => false
  property :verified_on_date,     Date, :nullable => false
  property :created_by_user_id,   Integer, :nullable => false
  property :created_at,           DateTime, :nullable => false, :default => DateTime.now
  
  belongs_to :loan_application
  
  validates_with_method :one_status_only_per_CPV, :record_CPV2_only_when_CPV1_approved

  # A CPV can only be approved or rejected
  def one_status_only_per_CPV
    statuses = ClientVerification.get_all_CPV_status(loan_application_id)
    status_for_type = statuses[self.verification_type]
    return [false, "Only one status can be recorded for #{self.verification_type} for #{self.loan_application_id}"] unless status_for_type == Constants::Verification::NOT_VERIFIED
    true
  end

  # CPV2 is only applicable when CPV1 is approved
  def record_CPV2_only_when_CPV1_approved
    return true unless self.verification_type == Constants::Verification::CPV2
    cpv1_is_verified = ClientVerification.is_CPV1_verified?(self.loan_application_id)
    return [false, "CPV2 can only be recorded for a client that has been approved through CPV1"] unless cpv1_is_verified
    true
  end

  # Get all CPVs' Info objects on the given loan application
  def self.get_CPVs_infos(for_loan_application)
    cpv_info = {}

    cpv1 = get_CPV1(for_loan_application)
    cpv_info[CPV1] = cpv1 ? cpv1.to_info : nil

    cpv2 = get_CPV2(for_loan_application)
    cpv_info[CPV2] = cpv2 ? cpv2.to_info : nil

    cpv_info
  end

  # Get all CPVs on the loan application
  def self.get_CPVs(for_loan_application)
    first(:loan_application_id => for_loan_application)
  end

  # Get CPV1 on the loan application -- remember: this returns a collection
  def self.get_CPV1(for_loan_application)
    first(:loan_application_id => for_loan_application, :verification_type => CPV1)
  end

  # Get CPV2 on the loan application -- remember: this returns a collection
  def self.get_CPV2(for_loan_application)
    first(:loan_application_id => for_loan_application, :verification_type => CPV2)
  end

  # Submit an approved CPV1
  def self.record_CPV1_approved(loan_application_id, by_staff, on_date, by_user_id)
    record_verification(loan_application_id, CPV1, VERIFIED_ACCEPTED, by_staff, on_date, by_user_id)
  end

  # Submit a rejected CPV1
  def self.record_CPV1_rejected(loan_application_id, by_staff, on_date, by_user_id)
    record_verification(loan_application_id, CPV1, VERIFIED_REJECTED, by_staff, on_date, by_user_id)
  end

  # Submit an approved CPV2
  def self.record_CPV2_approved(loan_application_id, by_staff, on_date, by_user_id)
    record_verification(loan_application_id, CPV2, VERIFIED_ACCEPTED, by_staff, on_date, by_user_id)
  end

  # Submit a rejected CPV2
  def self.record_CPV2_rejected(loan_application_id, by_staff, on_date, by_user_id)
    record_verification(loan_application_id, CPV2, VERIFIED_REJECTED, by_staff, on_date, by_user_id)
  end

  # Get CPV1 status on the loan application
  def self.get_CPV1_status(loan_application_id)
    get_CPV_status(loan_application_id, CPV1)
  end

  # Query for whether the loan application is CPV1 accepted
  def self.is_CPV1_verified?(loan_application_id)
    get_CPV1_status(loan_application_id) == VERIFIED_ACCEPTED
  end

  # Get CPV2 status on the loan application
  def self.get_CPV2_status(loan_application_id)
    get_CPV_status(loan_application_id, CPV2)
  end

  # Get the status of all CPVs performed on a loan application as a hash with the CPV names as keys
  def self.get_all_CPV_status(loan_application_id)
    statuses = {}
    statuses[Constants::Verification::CPV1] = get_CPV1_status(loan_application_id)
    statuses[Constants::Verification::CPV2] = get_CPV2_status(loan_application_id)
    statuses
  end

  # Query for whether the loan application is CPV2 accepted
  def self.is_CPV2_verified?(loan_application_id)
    get_CPV2_status(loan_application_id) == VERIFIED_ACCEPTED
  end

  #check whether the whole CPV process is complete on a given Loan Application
  def self.is_cpv_complete?(loan_application_id)
    #a CPV is deemed complete only when BOTH CPV1 and CPV2 are complete (either rejected or approved, but not NOT_VERIFIED)
    if get_CPV1_status(loan_application_id) == NOT_VERIFIED
      return false
    end
    
    if get_CPV1_status(loan_application_id) == VERIFIED_ACCEPTED and get_CPV2_status(loan_application_id) == NOT_VERIFIED
      return false
    end
    
    #when a CPV2 is done, it's complete.
    #the validation rules on models ensure that CPV2 won't happen before CPV1
    if get_CPV2_status(loan_application_id) == VERIFIED_ACCEPTED or get_CPV2_status(loan_application_id) == VERIFIED_REJECTED
      return true
    end
  
    #when the CPV1 is rejected, the process is complete. Because CPV2 won't happen any longer.
    if get_CPV1_status(loan_application_id) == VERIFIED_REJECTED 
      return true
    end

  end
  
  #returns an info model for this ClientVerification
  def to_info
    ClientVerificationInfo.new(
      self.loan_application_id,
      self.verification_type,
      self.verification_status,
      self.verified_by_staff_id,
      self.verified_on_date,
      self.created_by_user_id,
      self.created_at
    )
  end

  #returns a bunch of CPV information objects related to this loan application id
  def self.get_all_CPV_information(loan_application_id)
    cpvs = get_CPVs(loan_application_id)
    cpvinfos = []
    cpvs.each {|c| cpvinfos.push(c.to_info)} 

    cpvinfos
  end

  private

  # Queries CPV status for a loan application
  def self.get_CPV_status(loan_application_id, verification_type)
    cpv = first(:loan_application_id => loan_application_id, :verification_type => verification_type)
    return NOT_VERIFIED unless cpv
    cpv.verification_status
  end

  # Creates a new CPV record
  def self.record_verification(loan_application_id, verification_type, verification_status, by_staff, on_date, by_user_id)
    create(:loan_application_id => loan_application_id,
      :verification_type => verification_type,
      :verification_status => verification_status,
      :verified_by_staff_id => by_staff,
      :verified_on_date => on_date,
      :created_by_user_id => by_user_id)
  end

end

#An in-memory class containing all information about a ClientVerification
class ClientVerificationInfo
  attr_reader :loan_application_id, :verification_type, :verification_status, :verified_by_staff_id, :verified_on_date, :created_by_user_id, :created_at

  def initialize(loan_application_id, verification_type, verification_status, verified_by_staff_id, verified_on_date, created_by_user_id, created_at)
    @loan_application_id = loan_application_id
    @verification_type = verification_type
    @verification_status = verification_status
    @verified_by_staff_id = verified_by_staff_id
    @verified_on_date = verified_on_date
    @created_by_user_id = created_by_user_id
    @created_at = created_at
  end
end
