class HolidayAdministration

  include DataMapper::Resource
  include Constants::Properties, Constants::Loan

  property :id,                    Serial
  property :effective_on,          *DATE_NOT_NULL
  property :performed_by,          *INTEGER_NOT_NULL
  property :recorded_by,           *INTEGER_NOT_NULL
  property :created_at,            *CREATED_AT

  belongs_to :location_holiday, :nullable => true
  belongs_to :biz_location

  validates_with_method :move_work_to_date_holiday?
  validates_with_method :only_one_holiday_at_a_location_on_date?

  def move_work_to_date_holiday?
    holiday = LocationHoliday.get_any_holiday(self.biz_location, self.location_holiday.move_work_to_date)
    self.location_holiday.id != holiday.id && holiday.blank? ? true : [false, "There is already Holiday defined on Move Date(#{self.location_holiday.move_work_to_date}) for location(#{self.biz_location.name})"]
  end

  def only_one_holiday_at_a_location_on_date?
    existing_holiday_on_date = HolidayAdministration.first('location_holiday.on_date' => self.location_holiday.on_date, :biz_location => self.biz_location)
    existing_holiday_on_date && self.location_holiday.id != existing_holiday_on_date.location_holiday.id ? [false, "There is already a holiday: #{existing_holiday_on_date.location_holiday.to_s} in force at the location(#{existing_holiday_on_date.biz_location.name})"] : true
  end
  
  def self.holiday_setup(holiday_id, location_id, on_date, staff_id, user_id)

    fee_admin = self.new
    fee_admin[:location_holiday_id] = holiday_id
    fee_admin[:biz_location_id]     = location_id
    fee_admin[:effective_on]        = on_date
    fee_admin[:performed_by]        = staff_id
    fee_admin[:recorded_by]         = user_id
    fee_admin.save
  end

  def self.get_location_holiday(location_id, on_date = Date.today)
    search                    = {}
    search[:biz_location_id]  = location_id
    search[:effective_on.lte] = on_date
    holiday_admins            = all(search)
    holiday_admins.blank? ? [] : holiday_admins.map(&:location_holiday)
  end
end