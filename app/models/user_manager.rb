class UserManager
  include Constants::User

  attr_reader :created_at
  
  def initialize; @created_at = DateTime.now; end

  def get_user(for_user_id)
    user = User.get(for_user_id)
    raise Errors::DataError, "Unable to locate user with ID: #{for_user_id}" unless user
    user
  end

  def get_staff_member(for_staff_member_id)
    staff_member = StaffMember.get(for_staff_member_id)
    raise Errors::DataError, "Unable to locate staff member with ID: #{for_staff_member_id}" unless staff_member
    staff_member    
  end

  def get_user_for_login(login)
    user = User.first(:login => login)
    raise Errors::DataError, "Unable to locate user with login: #{login}" unless user
    user
  end

  def get_first_user
    User.first
  end

  def get_operator
    all_users = User.all
    operator = nil
    all_users.each { |user|
      operator = user if user.role == OPERATOR
      break if operator
    }
    operator
  end

  def all_active_staff
    StaffMember.all(:active => true)
  end

  def all_staff_at_location(location_id, on_date = Date.today)
    posting_location_id = location_id
    for_location = BizLocation.get(location_id)
    raise Errors::InvalidConfigurationError, "No location was found for the ID: #{location_id}" unless for_location
    if for_location.is_nominal_center?
      parent_location = LocationLink.get_parent(for_location, on_date)
      raise Errors::InvalidConfigurationError, "The center #{for_location.to_s} does not appear to have been assigned to a branch on date #{on_date}" unless parent_location
      posting_location_id = parent_location.id
    end
    staff_postings = StaffPosting.get_staff_assigned(posting_location_id, on_date)
    return staff_postings if staff_postings.empty?
    staff_postings.collect {|posting| posting.staff_assigned}
  end

  def active_staff_not_currently_posted
    StaffMember.all
=begin
    StaffPosting.active_staff_not_currently_posted
=end
  end

  def staff_managing_location(location_id, on_date = Date.today)
    StaffMember.all
=begin
    location_management = LocationManagement.staff_managing_location(location_id, on_date)
    location_management ? location_management.manager_staff_member : nil
=end
  end

  # This is the list of staff members that can potentially be assigned to manage any location at a particular location level
  def staff_that_can_manage_locations_at_level(location_level_number, on_date = Date.today)
    StaffMember.all
=begin
    StaffMember.all(:creation_date.lte => on_date)
=end
  end

  # The is the list of staff that can potentially be assigned to manage the "children" locations under the specified location on the specified date
  def staff_that_can_manage_locations_under_location(location_id, on_date = Date.today)
    StaffMember.all
=begin
    StaffMember.all(:creation_date.lte => on_date)
=end
  end

  # This is the list of staff that can potentially be assigned to manage a particular location on the specified date
  def staff_that_can_manage_specific_location(location_id, on_date = Date.today)
    StaffMember.all
=begin    
    StaffMember.all(:creation_date.lte => on_date)
=end
  end

  def staff_that_can_manage_location_excluding_staff(location_id, staff_member_id, on_date = Date.today)
    staff_member_to_exclude = get_staff_member(staff_member_id)
    all_staff_that_can_manage = staff_that_can_manage_specific_location(location_id, on_date)
    all_staff_that_can_manage.empty? ? [] : all_staff_that_can_manage - [staff_member_to_exclude]
  end

  def support_staff_at_location(location_id, on_date = Date.today)
    all_local_staff = all_staff_at_location(location_id, on_date)
    all_local_staff.select {|staff_member| staff_member.is_support?}
  end

end
