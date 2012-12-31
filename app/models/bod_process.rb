class BodProcess
  include DataMapper::Resource
  include Constants::Properties
  include Constants::ProcessVerificationStatus

  property :id,           Serial
  property :on_date,      *DATE_NOT_NULL
  property :status,       Enum.send('[]', *VERIFICATION_STATUSES), :nullable => false, :default => PENDING
  property :created_on,   *DATE_NOT_NULL
  property :started_at,   DateTime
  property :completed_at, DateTime
  property :created_at,   *CREATED_AT
  property :performed_by, Integer
  property :created_by,   Integer

  validates_with_method  :created_on, :method => :not_in_future?

  belongs_to :biz_location
  belongs_to :user, :child_key => [:created_by], :model => 'User'
  belongs_to :staff_member, :child_key => [:performed_by], :model => 'StaffMember'

  def self.bod_process_for_location(location_ids, performed_by_id, created_by_id, on_date = Date.today)
    biz_locations = BizLocation.all(:id => location_ids)
    biz_locations.each do |location|
      eod = first(:on_date => on_date, :biz_location_id => location.id)
      eod.update(:started_at => Time.now, :performed_by => performed_by_id, :created_by => created_by_id, :status => IN_PROCESS)
      eod.run_bod_process_in_thread
    end
  end

  def self.create_default_bod_for_location(location_ids, created_on = Date.today, on_date = Date.today)
    location_ids.each do |location_id|
      first_or_create(:on_date => on_date, :created_on => created_on, :biz_location_id => location_id)
    end
  end

  def run_bod_process_in_thread
    bk = MyBookKeeper.new
    user = self.user
    loans = LoanAdministration.get_loans_accounted_by_sql(self.biz_location.id, self.on_date)
    loans = loans.compact.uniq unless loans.blank?
    loans.each do |loan|
      LoanDueStatus.generate_loan_due_status(loan.id, self.on_date)
      bk.accrue_all_receipts_on_loan_till_date(loan, self.on_date) if loan.is_outstanding?
      accrual_transactions = get_reporting_facade(user).all_accrual_transactions_recorded_on_date(self.on_date, loan.id)
      accrual_transactions.each{|accrual| bk.account_for_accrual(accrual)} unless accrual_transactions.blank?
    end
    #Ledger.run_branch_bod_accounting(self.biz_location, self.on_date)
    self.update(:completed_at => Time.now, :status => COMPLETED)
  end

  def not_in_future?
    return true if created_on and (created_on<=Date.today)
    [false, "BOD cannot be done on future dates"]
  end

  def get_reporting_facade(user)
    @reporting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, user)
  end

  def get_loan_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOAN_FACADE, user)
  end

end
