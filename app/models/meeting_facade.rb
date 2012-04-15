class MeetingFacade

  attr_reader :user_id, :created_at

  def initialize(user_id)
    @user_id = user_id; @created_at = DateTime.now
  end

  # This returns a meeting for the given location on the date,
  # or nil if there is none currently scheduled
  def get_meeting(for_location, on_date)
    #TBD
  end
  
  # This returns a series of meetings for the location commencing on or after 
  # the specified date, and an empty list when there are none
  def get_meeting_calendar(for_location, beginning_on)
    #TBD
  end

  # Creates a new meeting schedule for the given location
  def setup_meeting_schedule(for_location, meeting_schedule_info)
    #TBD
  end

  # Creates a holiday at the location as specified
  def setup_holiday(for_location, holiday_info)
    #TBD
  end

  # Returns any holiday that is in force for the given location on date
  def get_holiday(for_location, on_date)
    #TBD
  end

  # This returns a series of holidays for the location commencing on or after
  # the specified date, and an empty list when there are none
  def get_holiday_calendar(at_location, beginning_on)
    #TBD
  end

end
