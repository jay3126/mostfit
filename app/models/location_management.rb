class LocationManagement
  include DataMapper::Resource
  include Constants::Properties
  include Comparable

  property :id,                  Serial
  property :manager_staff_id,    *INTEGER_NOT_NULL
  property :managed_location_id, *INTEGER_NOT_NULL
  property :effective_on,        *DATE_NOT_NULL
  property :performed_by,        *INTEGER_NOT_NULL
  property :recorded_by,         *INTEGER_NOT_NULL
  property :created_at,          *CREATED_AT

  validates_with_method :only_one_assignment_on_date?
  validates_with_method :assignment_and_creation_dates_are_valid?
  validates_with_method :staff_member_is_active?

  def only_one_assignment_on_date?
    already_assigned_on_date = LocationManagement.first(:managed_location_id => self.managed_location_id, :effective_on => self.effective_on)
    already_assigned_on_date ? [false, "There is already a staff member assigned to manage the location on the date: #{self.effective_on}"] :
        true
  end

  def assignment_and_creation_dates_are_valid?
    Validators::Assignments.is_valid_assignment_date?(effective_on, manager_staff_member, managed_location)
  end
  
  def staff_member_is_active?
    if self.manager_staff_member
      validate_value = self.manager_staff_member.active ? true :
        [false, "Inactive staff member cannot be assigned to manage a location"]
      return validate_value
    end
    true
  end

  def managed_location; BizLocation.get(self.managed_location_id); end
  def manager_staff_member; StaffMember.get(self.manager_staff_id); end

  def <=>(other)
    other.respond_to?(:effective_on) ? (other.effective_on <=> self.effective_on) : nil
  end

  def self.assign_manager_to_location(staff_member, location, effective_on, performed_by, recorded_by)
    Validators::Arguments.not_nil?(staff_member, location, effective_on, performed_by, recorded_by)

    raise ArgumentError, "Staff member assigned is not a valid instance" unless staff_member.is_a?(StaffMember)
    raise ArgumentError, "Location to be assigned is not a valid instance" unless location.is_a?(BizLocation)

    management = {}
    management[:manager_staff_id]    = staff_member.id
    management[:managed_location_id] = location.id
    management[:effective_on]        = effective_on
    management[:performed_by]        = performed_by
    management[:recorded_by]         = recorded_by

    location_manager = create(management)
    raise Errors::DataError, location_manager.errors.first.first unless location_manager.saved?
    location_manager
  end

  def self.staff_managing_location(location_id, on_date = Date.today)
    Validators::Arguments.not_nil?(location_id, on_date)
    staff_query = {}
    staff_query[:managed_location_id] = location_id
    staff_query[:effective_on.lte]    = on_date
    staff_query[:order]               = [:effective_on.desc]
    first(staff_query)
  end

  def self.locations_managed_by_staff(staff_id, on_date = Date.today)
    Validators::Arguments.not_nil?(staff_id, on_date)

    locations_query = {}
    locations_query[:manager_staff_id] = staff_id
    locations_query[:effective_on.lte] = on_date
    all_managed_instances_at_any_time = all(locations_query)

    return [] if all_managed_instances_at_any_time.empty?

    all_managed_locations_at_any_time = (all_managed_instances_at_any_time.collect {|instance| instance.managed_location_id}).uniq
    currently_managed_locations = []
    all_managed_locations_at_any_time.each { |location_id|
      currently_managed_instance = staff_managing_location(location_id, on_date)
      currently_managed_locations.push(currently_managed_instance) if currently_managed_instance.manager_staff_id == staff_id
    }
    currently_managed_locations
  end

end