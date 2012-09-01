class LocationFacade < StandardFacade
  include Constants::Space
  # Facade for all queries and operations on locations (such as Region, Area,
  # Branch, Center, etc.) and relationships between these

  ###########
  # QUERIES #
  ###########

  def visible_locations(for_staff_id, on_date = Date.today)
    location_manager.visible_locations(for_staff_id, on_date)
  end

  # Returns a map of all the different kinds of locations that can have meetings
  def all_locations_that_can_meet
    LocationManager.all_locations_that_can_meet
  end

  # Get a BizLocation instance by ID
  def get_location(given_id)
    BizLocation.get(given_id)
  end

  # Get a LocationLevel instance by specifying the level number
  def get_location_level(by_number)
    LocationLevel.get_level_by_number(by_number)
  end

  # Get all location levels
  def all_location_levels
    location_manager.all_location_levels
  end

  # Returns a list of all the BizLocations at the specified location level
  def all_locations_at_level(by_level_number)
    location_manager.all_locations_at_level(by_level_number)
  end

  # Old Mostfit has regions, areas, branches, and centers. So this returns a list of branches
  # under whatever corresponds to a 'branch' under the new configurable hierarchy of location levels
  def all_nominal_branches
    location_manager.all_nominal_branches
  end

  # Old Mostfit has regions, areas, branches, and centers. So this returns a list of centers
  # under whatever corresponds to a 'center' under the new configurable hierarchy of location levels
  def all_nominal_centers
    location_manager.all_nominal_centers
  end

  # Get the 'parent' BizLocation for the specified 'child' BizLocation on the given date, if one exists
  def get_parent(for_location, on_date = Date.today)
    LocationLink.get_parent(for_location, on_date)
  end

  # Get the 'children' BizLocation assigned to the specified 'parent' BizLocation on the given date
  def get_children(for_location, on_date = Date.today)
    LocationLink.get_children(for_location, on_date)
  end

  ###########
  # QUERIES # on loans at location begins
  ###########

  def get_loans_administered(at_location_id, on_date = Date.today)
    LoanAdministration.get_loans_administered(at_location_id, on_date)
  end

  def get_loans_accounted(at_location_id, on_date = Date.today)
    LoanAdministration.get_loans_accounted(at_location_id, on_date)
  end

  ###########
  # QUERIES # on loans at location ends
  ###########

  ###########
  # UPDATES #
  ###########

  # Assign the BizLocation as a 'child' to the parent BizLocation, effective on the specified date
  def assign(child, to_parent, on_date = Date.today)
    LocationLink.assign(child, to_parent, on_date)
  end

  # Create a new location level
  def create_next_level(name, on_creation_date)
    LocationLevel.create_next_level(name, on_creation_date)
  end

  # Create a new location by specifying the name, the creation date, and the level number (not the level)
  def create_new_location(by_name, on_creation_date, at_level_number, address = nil, defualt_disbursal_date = nil)
    BizLocation.create_new_location(by_name, on_creation_date, at_level_number, address, defualt_disbursal_date)
  end

  # Assign administered_at and accounted_at locations to loan
  def assign_locations_to_loan(administered_at, accounted_at, to_loan, performed_by, recorded_by, effective_on = Date.today)
    LoanAdministration.assign(administered_at, accounted_at, to_loan, performed_by, recorded_by, effective_on)
  end

  # Find staff_member that is manage location on date
  def location_managed_by_staff(location_id, on_date = Date.today)
    LocationManagement.staff_managing_location(location_id, on_date)
  end

  private

  def location_manager
    @location_manager ||= LocationManager.new
  end

end