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
      bod = first(:on_date => on_date, :biz_location_id => location.id)
      unless bod.blank?
        bod.update(:started_at => Time.now, :performed_by => performed_by_id, :created_by => created_by_id, :status => IN_PROCESS)
        if location.bod_processes.count == 1
          bod.run_bod_process_in_thread_first_time
        else
          bod.run_bod_process_in_thread
        end
      end
    end
  end

  def self.create_default_bod_for_location(location_ids, created_on = Date.today, on_date = Date.today)
    location_ids.each do |location_id|
      first_or_create(:on_date => on_date, :created_on => created_on, :biz_location_id => location_id)
    end
  end

  def run_bod_process_in_thread
    Thread.new {
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
    }
  end

  def run_bod_process_in_thread_first_time
    Thread.new {
      bk = MyBookKeeper.new
      first_date = self.on_date.first_day_of_month
      last_month_last_date = first_date - 1
      last_date = self.on_date.last_day_of_month
      loans = LoanAdministration.get_loan_ids_group_vise_accounted_by_sql(self.biz_location.id, last_month_last_date)
      disbursed_loans = loans[:disbursed_loan_status]
      repaid_loans = loans[:repaid_loan_status]
      write_off_loans = loans[:written_off_loan_status]
      preclouse_loans = loans[:preclosed_loan_status]
      total_loans = preclouse_loans+write_off_loans+disbursed_loans+repaid_loans
      total_loans.each do |loan_id|
        if disbursed_loans.include?(loan_id)
          status = :disbursed_loan_status
        elsif repaid_loans.include?(loan_id)
          status = :repaid_loan_status
        elsif write_off_loans.include?(loan_id)
          status =:written_off_loan_status
        elsif preclouse_loans.include?(loan_id)
          status = :preclosed_loan_status
        else
          status = ''
        end
        bk.accrue_regular_receipts_on_loan_till_date_dec(loan_id, status, last_month_last_date) unless status.blank?
      end

      loans_j = LoanAdministration.get_loan_ids_group_vise_accounted_by_sql(self.biz_location.id, self.on_date)
      disbursed_loans_j = loans_j[:disbursed_loan_status]
      repaid_loans_j = loans_j[:repaid_loan_status]
      write_off_loans_j = loans_j[:written_off_loan_status]
      preclouse_loans_j = loans_j[:preclosed_loan_status]
      total_loans_j = preclouse_loans_j+write_off_loans_j+disbursed_loans_j+repaid_loans_j
      total_loans_j.each do |loan_id|
        if disbursed_loans_j.include?(loan_id)
          status = :disbursed_loan_status
        elsif repaid_loans_j.include?(loan_id)
          status = :repaid_loan_status
        elsif write_off_loans_j.include?(loan_id)
          status =:written_off_loan_status
        elsif preclouse_loans_j.include?(loan_id)
          status = :preclosed_loan_status
        else
          status = ''
        end
        bk.accrue_broken_period_interest_receipts_reverse_on_date(loan_id, first_date)
        bk.accrue_regular_receipts_on_loan_from_date_to_date(loan_id, status, first_date, last_date) unless status.blank?
      end

      #Ledger.run_branch_bod_accounting(self.biz_location, self.on_date)
      self.update(:completed_at => Time.now, :status => COMPLETED)
    }
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
