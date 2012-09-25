class LocationHoliday
  include DataMapper::Resource
  include Constants::Space
  include Constants::Properties
  
  property :id,                 Serial
  property :name,               *NAME
  property :on_date,            *DATE_NOT_NULL
  property :move_work_to_date,  *DATE_NOT_NULL
  property :performed_by,       *INTEGER_NOT_NULL
  property :recorded_by,        *INTEGER_NOT_NULL
  property :created_at,         *CREATED_AT

  has n, :holiday_administrations
  has n, :biz_locations, :through => :holiday_administrations

  validates_with_method :only_one_holiday_at_a_location_on_date?

  def only_one_holiday_at_a_location_on_date?
    existing_holiday_on_date = HolidayAdministration.first('location_holiday.on_date' => self.on_date, :biz_location => self.biz_locations)
    existing_holiday_on_date && self.id != existing_holiday_on_date.location_holiday.id ? [false, "There is already a holiday: #{existing_holiday_on_date.location_holiday.to_s} in force at the location(#{existing_holiday_on_date.biz_location.name})"] : true
  end

  def to_s; "Holiday #{name} on #{on_date}"; end

  def performed_by_staff; StaffMember.get(performed_by) end;

  validates_is_unique :name

  # Creates a holiday for a location
  def self.setup_holiday(at_locations, holiday_name, on_date, move_work_to_date, performed_by_id, recorded_by_id)
    errors = []
    holiday_params = {}
    holiday_administration = {}
    holiday_admins = []
    child_locations = []
    holiday_params[:name] = holiday_name
    holiday_params[:on_date] = on_date
    holiday_params[:move_work_to_date] = move_work_to_date
    holiday_params[:performed_by] = performed_by_id
    holiday_params[:recorded_by] = recorded_by_id
    holiday = new(holiday_params)
    raise Errors::DataError, holiday.errors.first.join('<br>') unless holiday.valid?
    at_locations.each do |location|
      holiday_administration[location.id] = {}
      holiday_administration[location.id][:performed_by] = performed_by_id
      holiday_administration[location.id][:recorded_by]  = recorded_by_id
      holiday_administration[location.id][:biz_location] = location
      holiday_administration[location.id][:effective_on] = on_date
      holiday_admins << holiday.holiday_administrations.new(holiday_administration[location.id])
    end
    holiday_admins.each{|hd| errors << hd.errors.first.join('<br>') unless hd.valid?}
    raise Errors::DataError, errors unless errors.blank?
    holiday.save
    at_locations.each{|location| child_locations << LocationLink.all_children(location)}
    BaseScheduleLineItem.all('loan_base_schedule.lending.administered_at_origin' => child_locations.flatten.uniq.map(&:id), :on_date => on_date).update(:on_date => move_work_to_date)
    MeetingCalendar.all(:location_id => child_locations.flatten.uniq.map(&:id),:on_date => on_date).update(:on_date => move_work_to_date)
    holiday
  end

  def update_holiday(at_locations, holiday_name, on_date, move_work_to_date)
    errors = []
    holiday_administration = {}
    holiday_admins = []
    child_locations = []
    self.name = holiday_name
    self.on_date = on_date
    self.move_work_to_date = move_work_to_date
    raise Errors::DataError, self.errors.first.join('<br>') unless self.valid?
    at_locations.each do |location|
      holiday_administration[location.id] = {}
      holiday_administration[location.id][:performed_by] = self.performed_by
      holiday_administration[location.id][:recorded_by]  = self.recorded_by
      holiday_administration[location.id][:biz_location] = location
      holiday_administration[location.id][:effective_on] = on_date
      holiday_admins << self.holiday_administrations.new(holiday_administration[location.id])
    end
    holiday_admins.each{|hd| errors << hd.errors.first.join('<br>') unless hd.valid?}
    raise Errors::DataError, errors unless errors.blank?
    self.save
    at_locations = self.reload.biz_locations
    at_locations.each{|location| child_locations << LocationLink.all_children(location) << location}
    BaseScheduleLineItem.all('loan_base_schedule.lending.administered_at_origin' => child_locations.flatten.uniq.map(&:id), :on_date => on_date).update(:on_date => move_work_to_date)
    MeetingCalendar.all(:location_id => child_locations.flatten.uniq.map(&:id),:on_date => on_date).update(:on_date => move_work_to_date)
    self
  end

  def self.save_holiday_for_location(for_location, holidays, performed_by, recorded_by)
    exist_holiday = HolidayAdministration.first('location_holiday.on_date' => holidays.map(&:on_date), :biz_location => for_location)
    raise Errors::DataError, "There is already a holiday: #{exist_holiday.location_holiday.to_s} in force at the location(#{for_location.name})" unless exist_holiday.blank?
    child_locations = LocationLink.all_children(for_location) << for_location
    holidays.each do |holiday|
      HolidayAdministration.holiday_setup(holiday.id, for_location.id, Date.today, performed_by, recorded_by)
      BaseScheduleLineItem.all('loan_base_schedule.lending.administered_at_origin' => child_locations.map(&:id), :on_date => holiday.on_date).update(:on_date => holiday.move_work_to_date)
      MeetingCalendar.all(:location_id => child_locations.map(&:id),:on_date => holiday.on_date).update(:on_date => holiday.move_work_to_date)
    end
  end
  
  # Get either specific holiday or umbrella holiday
  def self.get_any_holiday(at_location, on_date)
    get_specific_holiday(at_location, on_date) || get_umbrella_holiday(at_location, on_date)
  end

  # Get any holiday that applies
  def self.holiday_applies?(to_location, on_date)
    not (get_any_holiday(to_location, on_date).nil?)
  end

  def self.get_origin_move_date(at_location, move_date)
    parent_locations = LocationLink.all_parents(at_location, Date.today) << at_location
    HolidayAdministration.first('location_holiday.move_work_to_date' => move_date, :biz_location => parent_locations.flatten.uniq)
  end

  private

  # This returns the holiday that was created for a specific location
  def self.get_specific_holiday(at_location, on_date)
    at_location.location_holidays(:on_date => on_date)
  end

  # This returns any holiday that was created for a location that
  # 'encompasses' the specified location
  def self.get_umbrella_holiday(at_location, on_date)
    parent_location = LocationLink.get_parent(at_location, on_date)
    if parent_location
      specific_holiday_at_parent_location = get_specific_holiday(parent_location, on_date)
      if specific_holiday_at_parent_location
        return specific_holiday_at_parent_location
      else
        return get_umbrella_holiday(parent_location, on_date)
      end
    else
      return get_specific_holiday(parent_location, on_date)
    end
    nil
  end

end