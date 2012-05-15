class LocationManager
  include Constants::Space

  def self.all_locations_that_can_meet
    locations = []
    MEETINGS_SUPPORTED_AT.each { |location_type|
      klass = Constants::Space.to_klass(location_type)
      next unless klass
      location_level = LocationLevel.first(:name => klass)
      locations = location_level.biz_locations
    }
    locations
  end

end
