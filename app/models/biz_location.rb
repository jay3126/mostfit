class BizLocation
  include DataMapper::Resource
  include Identified
  include Pdf::LoanSchedule if PDF_WRITER
  
  property :id,         Serial
  property :name,       String, :nullable => false
  property :created_at, DateTime, :nullable => false, :default => DateTime.now
  property :creation_date, Date, :nullable => false, :default => Date.today
  property :deleted_at, ParanoidDateTime

  belongs_to :location_level
  has n, :meeting_schedules, :through => Resource
  has 1, :address
  has n, :permitted_pin_codes, 'AddressPinCode'
  has n, :location_holidays
  has 1, :cost_center

  has n, :origin_home_staff, :model => 'StaffMember', :child_key => [:origin_home_location_id]
  has n, :visit_schedules

  validates_with_method :location_level_precedes_biz_location?

  def location_level_precedes_biz_location?
    Validators::Assignments.is_valid_assignment_date?(self.creation_date, self, self.location_level)
  end

  def created_on; creation_date; end

  def address_text
    address ? address.full_address_text : "NOT SPECIFIED"
  end

  def all_pin_codes
    own_address_pin_code_ary = address ? [address.address_pin_code] : nil
    own_address_pin_code_ary ? (own_address_pin_code_ary + self.permitted_pin_codes).flatten.uniq : self.permitted_pin_codes
  end

  def level_number
    self.location_level.level
  end

  def is_nominal_branch?
    self.level_number == LocationLevel::NOMINAL_BRANCH_LEVEL
  end

  def is_nominal_center?
    self.level_number == LocationLevel::NOMINAL_CENTER_LEVEL
  end

  # Returns all locations that belong to LocationLevel
  def self.all_locations_at_level(by_level_number)
    level = LocationLevel.get_level_by_number(by_level_number)
    all(:location_level => level)
  end

  # Create a new location by specifying the name, the creation date, and the level number (not the level)
  def self.create_new_location(by_name, on_creation_date, at_level_number)
    raise ArgumentError, "Level numbers begin with zero" if (at_level_number < 0)
    level = LocationLevel.get_level_by_number(at_level_number)
    raise Errors::InvalidConfigurationError, "No level was located for the level number: #{at_level_number}" unless level
    location = {}
    location[:name] = by_name
    location[:creation_date] = on_creation_date
    location[:location_level] = level
    new_location = create(location)
    raise Errors::DataError, new_location.errors.first.first unless new_location.saved?
    new_location
  end

  # Gets the name of the LocationLevel that this location belongs to
  def level_name
    self.location_level and self.location_level.name ? self.location_level.name : nil
  end

  # Prints the level name, the name, and the ID
  def to_s
    "#{self.level_name ? self.level_name + " " : ""}#{self.name_and_id}"
  end

  def meeting_schedule_effective(on_date)
    query = {}
    query[:schedule_begins_on.lte] = on_date
    query[:order] = [:schedule_begins_on.desc]
    self.meeting_schedules.first(query)
  end

  def save_meeting_schedule(meeting_schedule)
    self.meeting_schedules << meeting_schedule
    save
  end

  def self.search(q, per_page=10)
    if /^\d+$/.match(q)
      BizLocation.all(:conditions => {:id => q}, :limit => per_page)
    else
      BizLocation.all(:conditions => ["name=? or name like ?", q, q+'%'], :limit => per_page)
    end
  end

  def self.map_by_level(*locations)
    raise ArgumentError, "#{locations} are not valid arguments" unless (locations and locations.is_a?(Array) and (not (locations.empty?)))
    location_map = {}
    locations.flatten!
    return location_map if locations.empty?
    locations.each {|biz_location|
      level = biz_location.location_level
      level_list = location_map[level] ||= []
      level_list.push(biz_location)
      location_map[level] = level_list
    }
    location_map
  end

  def location_eod_summary(user, on_date = Date.today)
    location_ids = self.location_level.level == LocationLevel::NOMINAL_BRANCH_LEVEL ? [self.id] : LocationLink.get_children(self, on_date).map(&:id)
    reporting_facade = FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, user)
    total_new_loan_application       = ''
    loans_pending_approval           = reporting_facade.loans_applied_by_branches_on_date(on_date, *location_ids)
    loans_approved_today             = reporting_facade.loans_approved_by_branches_on_date(on_date, *location_ids)
    loans_scheduled_for_disbursement = reporting_facade.loans_scheduled_for_disbursement_by_branches_on_date(on_date, *location_ids)
    loans_disbursed_today            = reporting_facade.loans_disbursed_by_branches_on_date(on_date, *location_ids)
    t_fee_collect                    = reporting_facade.all_aggregate_fee_receipts_by_branches(on_date, on_date, *location_ids)
    advance_values                   = reporting_facade.sum_all_outstanding_loans_balances_accounted_at_locations_on_date(on_date, *location_ids)
    #t_advance_adjusted               = advance_values[]

    t_repayment_due                  = reporting_facade.loans_scheduled_for_disbursement_by_branches_on_date(on_date, *location_ids)
    t_repayment_received             = reporting_facade.all_receipts_on_loans_accounted_at_locations_on_value_date(on_date, *location_ids)
    t_outstanding                    = reporting_facade.all_outstanding_loans_balances_accounted_at_locations_on_date(on_date, *location_ids)

    t_money_deposits_recorded_today       = reporting_facade.total_money_deposited_on_date_at_locations(on_date, *location_ids)
    t_money_deposits_verified_confirmed   = reporting_facade.total_money_deposited_verified_confirmed_on_date_at_locations(on_date, *location_ids)
    t_money_deposits_verified_rejected    = reporting_facade.total_money_deposited_verified_rejected_on_date_at_locations(on_date, *location_ids)
    t_money_deposits_pending_verification = reporting_facade.total_money_deposited_pending_verification_until_date_at_locations(on_date, *location_ids)

    EodSummary.new(total_new_loan_application, loans_pending_approval, loans_approved_today, loans_scheduled_for_disbursement, loans_disbursed_today,
                  t_repayment_due, t_repayment_received, t_outstanding, t_money_deposits_recorded_today, t_money_deposits_verified_confirmed,
                  t_money_deposits_verified_rejected,t_money_deposits_pending_verification).summary
  end
  
end
