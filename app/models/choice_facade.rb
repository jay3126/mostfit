class ChoiceFacade < StandardFacade

  # This is a list of all the locations (across various levels in the hierarchy) that is visible to the staff on the specified date
  def visible_locations(for_staff_id, on_date = Date.today)
    location_facade.visible_locations(for_staff_id, on_date)
  end

  def levels_that_support_designations
    LocationLevel.levels_that_support_designations
  end

  #TODO: move out of the facade
  def supervisors_and_executives_at_location(location_id, on_date = Date.today)
    all_staff = all_staff_at_location(location_id, on_date)
    all_staff.select {|staff_member| staff_member.is_supervisor_or_executive?}
  end

  def all_finops_and_supervisors_at_location(location_id, on_date = Date.today)
    all_staff = all_staff_at_location(location_id, on_date)
    all_staff.select {|staff_member| staff_member.is_finops_or_supervisor?}
  end

  def all_finops(location_id, on_date = Date.today)
    all_staff = all_staff_at_location(location_id, on_date)
    all_staff.select {|staff_member| staff_member.is_finops?}
  end

  # This is a list of staff members that are in the SUPPORT role at a given location on the specified date
  def support_staff_at_location(location_id, on_date = Date.today)
    user_facade.support_staff_at_location(location_id, on_date)
  end

  # This is a list of all staff at the particular location on the specified date
  def all_staff_at_location(location_id, on_date = Date.today)
    user_facade.all_staff_at_location(location_id, on_date)
  end

  # This is the list of staff that are not currently posted anywhere
  def active_staff_not_currently_posted
    user_facade.active_staff_not_currently_posted
  end

  # This is the staff managing a particular location on the specified date
  def staff_managing_location(location_id, on_date = Date.today)
    user_facade.staff_managing_location(location_id, on_date)
  end

  # This is the list of staff members that can potentially be assigned to manage any location at a particular location level
  def staff_that_can_manage_locations_at_level(location_level_number, on_date = Date.today)
    user_facade.staff_that_can_manage_locations_at_level(location_level_number, on_date)
  end

  # The is the list of staff that can potentially be assigned to manage the "children" locations under the specified location on the specified date
  def staff_that_can_manage_locations_under_location(location_id, on_date = Date.today)
    user_facade.staff_that_can_manage_locations_under_location(location_id, on_date)
  end

  # This is the list of staff that can potentially be assigned to manage a particular location on the specified date
  def staff_that_can_manage_specific_location(location_id, on_date = Date.today)
    user_facade.staff_that_can_manage_specific_location(location_id, on_date)
  end

  def staff_that_can_manage_location_excluding_staff(location_id, staff_member_id, on_date = Date.today)
    user_facade.staff_that_can_manage_location_excluding_staff(location_id, staff_member_id, on_date)
  end

  def available_loan_products(on_date = Date.today)
    configuration_facade.available_loan_products(on_date)
  end

  private

  def location_facade
    @location_facade ||= FacadeFactory.instance.get_other_facade(FacadeFactory::LOCATION_FACADE, self)
  end

  def user_facade
    @user_facade ||= FacadeFactory.instance.get_other_facade(FacadeFactory::USER_FACADE, self)
  end

  def configuration_facade
    @configuration_facade ||= FacadeFactory.instance.get_other_facade(FacadeFactory::CONFIGURATION_FACADE, self)
  end

end
