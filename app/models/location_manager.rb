class LocationManager
  include Constants::Space

  def self.all_locations_that_can_meet
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
