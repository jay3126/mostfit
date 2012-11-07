class LocationManager
  include Constants::Space

  def visible_locations(for_staff_id, on_date)
    Validators::Arguments.not_nil?(for_staff_id, on_date)
    staff_member = StaffMember.get(for_staff_id)

    role_class = staff_member.role
    locations_list = []

    if Constants::User::ROLES_THAT_CAN_VIEW_ALL_LOCATIONS.include?(role_class)
      locations_list = all_locations_on_date(on_date)
    else
      staff_posting = StaffPosting.get_assigned_location(for_staff_id, on_date)

      if staff_posting
        posting_location = staff_posting.assigned_to_location
        locations_list.push(posting_location)
        posting_location_children = LocationLink.get_children(posting_location, on_date)
        locations_list.push(posting_location_children) if (posting_location_children)
      end
    end

    locations_list.flatten!
    BizLocation.map_by_level(locations_list)
  end

  def self.all_locations_that_can_meet
    locations = []
    LocationLevel.all(:has_meeting => true).each { |location_level|
      locations << location_level.biz_locations
    }
    locations.flatten
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

  def all_nominal_areas
    all_locations_at_level(LocationLevel::NOMINAL_AREA_LEVEL)
  end

  def all_locations_on_date(on_date = Date.today)
    BizLocation.all(:creation_date.lte => on_date)
  end

end
