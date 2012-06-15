class LocationManagement
  include DataMapper::Resource
  include Constants::Properties

  property :id,           Serial
  property :staff_id,     *INTEGER_NOT_NULL
  property :location_id,  *INTEGER_NOT_NULL
  property :effective_on, *DATE_NOT_NULL
  property :recorded_by,  *INTEGER_NOT_NULL
  property :created_at,   *CREATED_AT
  property :deleted_at,   *DELETED_AT

  def biz_location; BizLocation.get self.location_id; end
  def staff; StaffMember.get self.staff_id; end

  def assign(staff, location, effective_on, recorded_by)
    Validators::Arguments.not_nil?(staff, location, effective_on, recorded_by)

    self.staff_id = staff.id
    self.location_id = location.id
    self.effective_on = effective_on
    self.recorded_by = recorded_by.id

    raise Error::DataError, self.error.first.join(', ') unless self.save
    self
  end

  def self.get_locations_for_staff(staff, on_date = Date.today)
    locations = all(:staff_id => staff.id, :effective_on.lte => on_date)
    locations.blank? ? [] : locations.map(&:biz_location).uniq
  end
end