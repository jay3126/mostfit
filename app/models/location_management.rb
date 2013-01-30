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

  belongs_to :biz_location, :child_key => [:managed_location_id]
  belongs_to :staff_member, :child_key => [:performed_by], :model => 'StaffMember'

  def only_one_assignment_on_date?
    assigned = LocationManagement.first(:managed_location_id => self.managed_location_id, :effective_on => self.effective_on)
    assigned && assigned.manager_staff_id != self.manager_staff_id ? [false, "There is already a staff member(#{assigned.manager_staff_member.name.humanize}) assigned to manage the location on the date: #{self.effective_on}"] : true
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

  def self.all_staffs_managing_location(location_id, on_date = Date.today)
    Validators::Arguments.not_nil?(location_id, on_date)
    staff_query = {}
    staff_query[:managed_location_id] = location_id
    staff_query[:effective_on.lte]    = on_date
    staff_query[:order]               = [:effective_on.desc]
    all(staff_query)
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

  def self.locations_managed_by_staff_by_sql(staff_id, on_date = Date.today)
    Validators::Arguments.not_nil?(staff_id, on_date)

    locations_query = {}
    locations_query[:manager_staff_id] = staff_id
    locations_query[:effective_on.lte] = on_date
    loaction_admin = all(locations_query)

    return [] if loaction_admin.empty?

    l_links = repository(:default).adapter.query("select * from (select * from location_managements where managed_location_id IN (#{loaction_admin.map(&:managed_location_id).join(',')})) la where la.manager_staff_id = (select manager_staff_id from (select * from location_managements where managed_location_id IN (#{loaction_admin.map(&:managed_location_id).join(',')})) la1 where la.managed_location_id = la1.managed_location_id AND la.manager_staff_id = #{staff_id} order by la1.effective_on desc limit 1 );")
    l_links.map(&:managed_location_id).blank? ? [] : BizLocation.all(:id => l_links.map(&:managed_location_id))
    
  end

  def self.location_ids_managed_by_staff_by_sql(staff_id, on_date = Date.today)
    Validators::Arguments.not_nil?(staff_id, on_date)

    locations_query = {}
    locations_query[:manager_staff_id] = staff_id
    locations_query[:effective_on.lte] = on_date
    loaction_admin = all(locations_query)

    return [] if loaction_admin.empty?

    l_links = repository(:default).adapter.query("select la.managed_location_id from (select * from location_managements where managed_location_id IN (#{loaction_admin.map(&:managed_location_id).join(',')})) la where la.manager_staff_id = (select manager_staff_id from (select * from location_managements where managed_location_id IN (#{loaction_admin.map(&:managed_location_id).join(',')})) la1 where la.managed_location_id = la1.managed_location_id AND la.manager_staff_id = #{staff_id} order by la1.effective_on desc limit 1 );")
    l_links.blank? ? [] : l_links

  end

  def self.staffs_ids_managed_to_location_by_sql(location_id, on_date = Date.today)
    Validators::Arguments.not_nil?(location_id, on_date)

    staff_query = {}
    staff_query[:managed_location_id] = location_id
    staff_query[:effective_on.lte]    = on_date
    staff_query[:order]               = [:effective_on.desc]
    location_admin                    = all(staff_query)

    return [] if location_admin.empty?

    staff_ids = repository(:default).adapter.query("select la.manager_staff_id from (select * from location_managements where manager_staff_id IN (#{location_admin.map(&:manager_staff_id).uniq.join(',')})) la where la.managed_location_id IN (#{location_admin.map(&:managed_location_id).uniq.join(',')}) and la.managed_location_id = (select la1.managed_location_id from (select * from location_managements where manager_staff_id IN (#{location_admin.map(&:manager_staff_id).uniq.join(',')})) la1 where la.managed_location_id = la1.managed_location_id AND la.manager_staff_id = la1.manager_staff_id order by la1.effective_on desc limit 1 );")
    staff_ids.blank? ? [] : staff_ids

  end

  def self.staffs_managed_to_location_by_sql(location_id, on_date = Date.today)
    staff_ids = staffs_ids_managed_to_location_by_sql(location_id, on_date)
    staff_ids.blank? ? [] : StaffMember.all(:id => staff_ids)
  end

  def self.check_valid_obj(staff_member, location, effective_on, performed_by, recorded_by)
    Validators::Arguments.not_nil?(staff_member, location, effective_on, performed_by, recorded_by)

    raise ArgumentError, "Staff member assigned is not a valid instance" unless staff_member.is_a?(StaffMember)
    raise ArgumentError, "Location to be assigned is not a valid instance" unless location.is_a?(BizLocation)

    management = {}
    management[:manager_staff_id]    = staff_member.id
    management[:managed_location_id] = location.id
    management[:effective_on]        = effective_on
    management[:performed_by]        = performed_by
    management[:recorded_by]         = recorded_by

    location_manager = new(management)
    raise Errors::DataError, location_manager.errors.first.join(', ') unless location_manager.valid?
    location_manager
  end

end