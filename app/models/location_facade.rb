class LocationFacade < StandardFacade
  include Constants::Space
  # Facade for all queries and operations on locations (such as Region, Area,
  # Branch, Center, etc.) and relationships between these

  # Returns a map of all the different kinds of locations that can have meetings
  def all_locations_that_can_meet
    locations = {}
    MEETINGS_SUPPORTED_AT.each { |location_type|
      klass = Constants::Space.to_klass(location_type)
      next unless klass
      all_instances = klass.all
      locations[location_type] = all_instances
    }
    locations
  end

end