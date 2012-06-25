class LocationManager
  include Constants::Space

  def self.all_locations_that_can_meet
    locations = []
    MEETINGS_SUPPORTED_AT.each { |location_type|
      klass = Constants::Space.to_klass(location_type)
      next unless klass
      location_level = LocationLevel.first :name => klass
      next unless location_level.has_meeting
      locations = location_level.biz_locations
    }
    locations
  end

  def all_location_levels
    LocationLevel.all
  end

  def all_locations_at_level(by_level_number)
    BizLocation.all_locations_at_level(by_level_number)
  end

  def all_nominal_branches
    all_locations_at_level(LocationLevel::NOMINAL_BRANCH_LEVEL)
  end

  def all_nominal_centers
    all_locations_at_level(LocationLevel::NOMINAL_CENTER_LEVEL)
  end

  def all_locations_on_date(on_date = Date.today)
    BizLocation.all(:creation_date.lte => on_date)
  end

end
