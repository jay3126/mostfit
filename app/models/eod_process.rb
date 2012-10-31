class EodProcess
  include DataMapper::Resource
  include Constants::Properties
  include Constants::EODProcessVerificationStatus

  property :id,           Serial
  property :on_date,      *DATE_NOT_NULL
  property :status,       Enum.send('[]', *EOD_VERIFICATION_STATUSES), :nullable => false, :default => PENDING
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

  def self.eod_process_for_location(location_ids, performed_by_id, created_by_id, on_date = Date.today)
    @biz_locations = BizLocation.all(:id => location_ids)
    @biz_locations.each do |location|
      eod = first(:on_date => on_date, :biz_location_id => location.id)
      eod.update(:started_at => Time.now, :performed_by => performed_by_id, :created_by => created_by_id, :status => IN_PROCESS)
      eod.run_eod_process_in_thread
      
    end
  end

  def self.create_default_eod_for_location(location_ids, created_on = Date.today, on_date = Date.today)
    location_ids.each do |location_id|
      first_or_create(:on_date => on_date, :created_on => created_on, :biz_location_id => location_id)
    end
  end

  def run_eod_process_in_thread
    Thread.new {
      bk = MyBookKeeper.new
      centers = LocationLink.all_children(self.biz_location, self.on_date)
      user = self.user
      loan_ids_for_advance = get_reporting_facade(user).all_oustanding_loan_IDs_scheduled_on_date_with_advance_balances(self.on_date)
      loans = LoanAdministration.get_loans_accounted(self.biz_location.id, self.on_date).compact
      custom_calendars = CustomCalendar.all(:on_date.gte => self.on_date).select{|d| d.on_date != d.collection_date && Date.parse(d.updated_at.to_s) == self.on_date}
      loans.each do |loan|
        loan_schedules = loan.loan_base_schedule.get_schedule_after_date(self.on_date)
        LoanDueStatus.generate_due_status_records_till_date(loan.id, self.on_date)
        get_loan_facade(user).adjust_advance(self.on_date, loan.id) if loan.is_outstanding? && loan_ids_for_advance.include?(loan.id)
        custom_loan_dates = custom_calendars.select{|s| loan_schedules.map(&:on_date).include?(s.on_date) && !s.collection_date.blank?}
        custom_loan_dates.each{|cd| loan.update_loan_shechdule_according_calendar_holiday(cd.on_date, cd.collection_date, self.on_date)}
      end
      Ledger.location_accounting_eod(self.biz_location, self.on_date)
      self.update(:completed_at => Time.now, :status => COMPLETED)
      Ledger.head_office_eod(self.on_date) if EodProcess.first(:on_date => self.on_date, :status.not => COMPLETED).blank?
    }
  end
  
  def self.head_office_eod(on_date = Date.today)
    Thread.new {
      Ledger.head_office_eod(on_date)
    }
  end

  def not_in_future?
    return true if created_on and (created_on<=Date.today)
    [false, "EOD cannot be done on future dates"]
  end

  def get_reporting_facade(user)
    @reporting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, user)
  end

  def get_loan_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOAN_FACADE, user)
  end

end
