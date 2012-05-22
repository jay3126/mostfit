class StaffAssignment
  include DataMapper::Resource
  include Constants::Properties
  
  property :id,             Serial
  property :staff_id,       *INTEGER_NOT_NULL
  property :designation_id, *INTEGER_NOT_NULL
  property :effective_on,   *DATE_NOT_NULL
  property :performed_by,   *INTEGER_NOT_NULL
  property :performed_at,   *INTEGER_NOT_NULL
  property :created_at,     *CREATED_AT
  property :deleted_at,     *DELETED_AT

  validates_with_method :only_one_designation_at_a_time?, :designation_and_location_are_consistent?

  # Ensures against a staff being assigned different designations
  def only_one_designation_at_a_time?
    #TODO
    true
  end

  # Staff is assigned to a location, and designations assigned must originate for the location level at such location on the specified date
  def designation_and_location_are_consistent?
    #TODO
    true
  end

  def staff; Staff.get(self.staff_id); end
  def designation; Designation.get(self.designation_id); end
  def performed_at_location; BizLocation.get(self.performed_at); end
  def performed_by_staff; Staff.get(self.performed_by); end
  def performed_at_location; BizLocation.get(self.performed_at_location); end

  # Get the staff designation on the specified date
  def self.get_designation(for_staff, on_date = Date.today)
    query                    = { }
    query[:staff_id]         = for_staff.id
    query[:effective_on.lte] = on_date
    query[:order]            = [:effective_on.desc]
    assignment               = first(query)
    assignment ? assignment.designation : nil
  end

  # Assign designation to staff commencing on the specified date
  def self.assign(designation, to_staff, performed_by, performed_at, effective_on = Date.today)
    assignment                  = { }
    assignment[:designation_id] = designation.id
    assignment[:staff_id]       = to_staff.id
    assignment[:effective_on]   = effective_on
    assignment[:performed_by]   = performed_by
    assignment[:performed_at]   = performed_at
    new_assignment              = create(assignment)
    raise Errors::DataError, new_assignment.errors.first.first unless new_assignment.saved?
    new_assignment
  end

  private

  # Returns the first assignment for the staff specifically on the given date
  def self.assignment_on_date(for_staff_id, on_date)
    staff_and_date = {}
    staff_and_date[:staff_id] = for_staff_id
    staff_and_date[:effective_on] = on_date
    first(staff_and_date)
  end

end