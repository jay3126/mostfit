class LocationFacade < StandardFacade
  include Constants::Space
  # Facade for all queries and operations on locations (such as Region, Area,
  # Branch, Center, etc.) and relationships between these

  # Returns a map of all the different kinds of locations that can have meetings
  def all_locations_that_can_meet
    LocationManager.all_locations_that_can_meet
  end

  def assign(child, to_parent, on_date = Date.today)
    LocationLink.assign(child, to_parent, on_date)
  end

  def get_parent(for_location, on_date = Date.today)
    LocationLink.get_parent(for_location, on_date)
  end

  def get_children(for_location, on_date = Date.today)
    LocationLink.get_children(for_location, on_date)
  end

end