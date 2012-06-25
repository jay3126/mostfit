class UserFacade
  include Singleton

  ###########
  # QUERIES # on user begin
  ###########

  def get_user(for_user_id)
    user_manager.get_user(for_user_id)
  end

  def get_user_for_login(login)
    user_manager.get_user_for_login(login)
  end

  def get_first_user
    user_manager.get_first_user
  end

  def get_operator
    user_manager.get_operator
  end

  ###########
  # QUERIES # on user end
  ###########

  def all_staff_at_location(location_id, on_date = Date.today)
    user_manager.all_staff_at_location(location_id, on_date)
  end

  def staff_managing_location(location_id, on_date = Date.today)
    user_manager.staff_managing_location(location_id, on_date)
  end

  # This is the list of staff members that can potentially be assigned to manage any location at a particular location level
  def staff_that_can_manage_locations_at_level(location_level_number, on_date = Date.today)
    user_manager.staff_that_can_manage_locations_at_level(location_level_number, on_date)
  end

  # The is the list of staff that can potentially be assigned to manage the "children" locations under the specified location on the specified date
  def staff_that_can_manage_locations_under_location(location_id, on_date = Date.today)
    user_manager.staff_that_can_manage_locations_under_location(location_id, on_date)
  end

  # This is the list of staff that can potentially be assigned to manage a particular location on the specified date
  def staff_that_can_manage_specific_location(location_id, on_date = Date.today)
    user_manager.staff_that_can_manage_specific_location(location_id, on_date)
  end

  def staff_that_can_manage_location_excluding_staff(location_id, staff_member_id, on_date = Date.today)
    user_manager.staff_that_can_manage_location_excluding_staff(location_id, staff_member_id, on_date)
  end

  def get_designation(for_staff_id, on_date)
    #TODO
  end

  ###########
  # UPDATES #
  ###########

  def assign_designation(designation, to_staff, performed_by, performed_at, effective_on = Date.today)
    #TODO
  end

  def user_manager
    @user_manager ||= UserManager.new
  end

end