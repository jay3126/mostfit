class LoanAuthorizationInfo
  include Constants::Status

  attr_reader :loan_application_id, :status, :performed_by_staff_id, :performed_on, :created_by_user_id, :created_at, :override_reason

  def initialize(loan_application_id, status, performed_by_staff_id, performed_on, created_by_user_id, created_at, override_reason = nil)
    @loan_application_id = loan_application_id
    @status = status
    @performed_by_staff_id = performed_by_staff_id
    @performed_on = performed_on
    @created_by_user_id = created_by_user_id
    @created_at = created_at
    @override_reason = override_reason if override_reason
  end

end

class LoanAuthorization
  include DataMapper::Resource
  include Constants::Status

  property :id,              Serial
  property :status,          Enum.send('[]', *APPLICATION_AUTHORIZATION_STATUSES), :nullable => false
  property :by_staff_id,     Integer, :nullable => false
  property :override_reason, Enum.send('[]', *LOAN_AUTHORIZATION_OVERRIDE_REASONS), :nullable => false, :default => REASON_FOR_NO_OVERRIDES
  property :performed_on,    Date, :nullable => false
  property :created_by,      Integer, :nullable => false
  property :created_at,      DateTime, :nullable => false, :default => DateTime.now

  belongs_to :loan_application

  def to_info
    LoanApplicationInfo.new(self.loan_application_id, self.status, self.by_staff_id, self.performed_on, self.created_by, self.created_at, self.override_reason)
  end

  validates_with_method :override_includes_reason?

  # No override reason needed if not overridden
  # Override reason is a must when overridden
  def override_includes_reason?
    return true if APPLICATION_AUTHORIZATION_NOT_OVERRIDES.include?(self.status)

    override_with_reason = ((APPLICATION_AUTHORIZATION_OVERRIDES.include?(self.status)) and (self.override_reason and self.override_reason != REASON_FOR_NO_OVERRIDES))
    override_with_reason ? true : [false, "Override reason is a must when authorization (#{self.status}) is an override"]
  end

  # Record authorization on loan application
  def self.record_authorization(on_loan_application, as_status, by_staff, on_date, by_user, with_override_reason = nil)
    query_params = {}
    query_params[:loan_application_id] = on_loan_application
    query_params[:status] = as_status
    query_params[:by_staff_id] = by_staff
    query_params[:performed_on] = on_date
    query_params[:created_by] = by_user
    query_params[:override_reason] = with_override_reason if with_override_reason
    create(query_params)
  end

  # Finds the authorization for a loan application, given the loan application id
  def self.get_authorization(on_loan_application)
    authorization = first(:loan_application_id => on_loan_application)
    authorization ? authorization.to_info : nil
  end

  # Whether a particular loan application is authorized approved
  def self.is_approved?(loan_application_id)
    authorization = first(:loan_application_id => loan_application_id)
    return false unless authorization
    status = authorization.status
    ((status == APPLICATION_APPROVED) or (status == APPLICATION_OVERRIDE_APPROVED))
  end

end