module Facade
  module Location
    include Constants::Space

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

    def all_location_meeting_schedules(on_date)
      locations_and_schedules = {}
      locations = all_locations_that_can_meet
      locations.each { |location_type, location_instances| 
        schedules = {}
        location_instances.each { |location| 
          ms = location.meeting_schedule_effective(on_date)
          schedules[location.id] =  ms if ms
        }
        locations_and_schedules[location_type] = schedules
      }
      locations_and_schedules
    end

  end
end

class LocationFacade
  include Facade::Location

  def initialize
    @created_at = DateTime.now
  end

  def to_s
    "Location facade instantiated at #{@created_at}"
  end

end