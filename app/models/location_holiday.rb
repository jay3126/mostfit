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

  belongs_to :biz_location

  def to_s; "Holiday #{name} at #{biz_location.to_s} on #{on_date}"; end

  def performed_by_staff; StaffMember.get(performed_by) end;

  validates_with_method :only_one_holiday_at_a_location_on_date?

  def only_one_holiday_at_a_location_on_date?
    existing_holiday_on_date = LocationHoliday.first(:on_date => self.on_date, :biz_location => self.biz_location)
    existing_holiday_on_date ? [false, "There is already a holiday: #{existing_holiday_on_date.to_s} in force at the location"] : true
  end

  # Creates a holiday for a location
  def self.setup_holiday(at_location, holiday_name, on_date, move_work_to_date, performed_by_id, recorded_by_id)
    holiday_params = {}
    holiday_params[:name] = holiday_name
    holiday_params[:on_date] = on_date
    holiday_params[:move_work_to_date] = move_work_to_date
    holiday_params[:performed_by] = performed_by_id
    holiday_params[:recorded_by] = recorded_by_id
    holiday_params[:biz_location] = at_location
    holiday = create(holiday_params)
    raise Errors::DataError, holiday.errors.first.first unless holiday.saved?
    holiday
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
    LocationHoliday.first(:move_work_to_date => move_date, :biz_location => parent_locations)
  end

  private

  # This returns the holiday that was created for a specific location
  def self.get_specific_holiday(at_location, on_date)
    LocationHoliday.first(:on_date => on_date, :biz_location => at_location)
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