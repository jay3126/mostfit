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
      operator = user if user.get_user_role == OPERATOR
      break if operator
    }
    operator
  end

  def all_staff_at_location(location_id, on_date = Date.today)
    staff_postings = StaffPosting.get_staff_assigned(location_id, on_date)
    return staff_postings if staff_postings.empty?

    staff_postings.collect {|posting| posting.staff_assigned}
  end

  def staff_managing_location(location_id, on_date = Date.today)
    location_management = LocationManagement.staff_managing_location(location_id, on_date)
    location_management ? location_management.manager_staff_member : nil
  end

  # This is the list of staff members that can potentially be assigned to manage any location at a particular location level
  def staff_that_can_manage_locations_at_level(location_level_number, on_date = Date.today)
    StaffMember.all(:creation_date.lte => on_date)
  end

  # The is the list of staff that can potentially be assigned to manage the "children" locations under the specified location on the specified date
  def staff_that_can_manage_locations_under_location(location_id, on_date = Date.today)
    StaffMember.all(:creation_date.lte => on_date)
  end

  # This is the list of staff that can potentially be assigned to manage a particular location on the specified date
  def staff_that_can_manage_specific_location(location_id, on_date = Date.today)
    StaffMember.all(:creation_date.lte => on_date)
  end

  def staff_that_can_manage_location_excluding_staff(location_id, staff_member_id, on_date = Date.today)
    staff_member_to_exclude = get_staff_member(staff_member_id)
    all_staff_that_can_manage = staff_that_can_manage_specific_location(location_id, on_date)
    all_staff_that_can_manage.empty? ? [] : all_staff_that_can_manage - [staff_member_to_exclude]
  end

end
