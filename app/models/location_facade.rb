class LocationFacade < StandardFacade
  include Constants::Space
  # Facade for all queries and operations on locations (such as Region, Area,
  # Branch, Center, etc.) and relationships between these

  ###########
  # QUERIES #
  ###########

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
    LocationLevel.all
  end

  # Returns a list of all the BizLocations at the specified location level
  def all_locations_at_level(by_level_number)
    BizLocation.all_locations_at_level(by_level_number)
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
  def create_new_location(by_name, on_creation_date, at_level_number)
    BizLocation.create_new_location(by_name, on_creation_date, at_level_number)
  end

end