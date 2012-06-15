class StaffPosting
  include DataMapper::Resource
  include Constants::Properties
  # Staff are assigned to different BizLocations at different points in time
  # via a StaffPosting

  property :id,           Serial
  property :staff_id,     *INTEGER_NOT_NULL
  property :at_location,  *INTEGER_NOT_NULL
  property :effective_on, *DATE_NOT_NULL
  property :performed_at, *INTEGER_NOT_NULL
  property :performed_by, *INTEGER_NOT_NULL
  property :performed_by, *INTEGER_NOT_NULL
  property :recorded_by,  *INTEGER_NOT_NULL
  property :created_at,   *CREATED_AT

  def staff_assigned; StaffMember.get(self.staff_id); end
  def assigned_to_location; BizLocation.get(self.at_location); end

  def self.get_staff_assigned(to_location_id, on_date = Date.today)
    staff_assigned = []
    locations = {}
    locations[:at_location] = to_location_id
    locations[:effective_on.lte] = on_date
    postings = all(locations)
    given_location = BizLocation.get(to_location_id)
    postings.each { |each_posting|
      staff = each_posting.staff_assigned
      staff_assigned.push(staff) if given_location == each_posting.assigned_to_location
    }
    staff_assigned.uniq
  end

  def self.get_assigned_location(for_staff_id, on_date = Date.today)
    assigned = {}
    assigned[:staff_id] = for_staff_id
    assigned[:effective_on.lte] = on_date
    assigned[:order] = [:effective_on.desc]
    location_assignment = first(assigned)
    location_assignment ? location_assignment.assigned_to_location : nil
  end

  def self.assign(staff_member, to_location, effective_on, performed_at, performed_by, recorded_by)
    Validators::Arguments.not_nil?(staff_member, to_location, effective_on, performed_at, performed_by, recorded_by)
    raise ArgumentError, "Staff member to be assigned is not an instance of StaffMember" unless staff_member.is_a?(StaffMember)
    raise ArgumentError, "Location to be assigned to is not an instance of BizLocation" unless to_location.is_a?(BizLocation)

    assignment = {}
    assignment[:staff_id] = staff_member.id
    assignment[:at_location]  = to_location.id
    assignment[:effective_on] = effective_on
    assignment[:performed_at] = performed_at
    assignment[:performed_by] = performed_by
    assignment[:recorded_by]  = recorded_by
    staff_posting = create(assignment)
    raise Errors::DataError, staff_posting.errors.first.first unless staff_posting.saved?
    staff_posting
  end

end