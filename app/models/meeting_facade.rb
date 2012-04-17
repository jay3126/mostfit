class MeetingFacade
  include Constants::Time
  
  # Use the facade to:
  # get meeting schedules for a location (Center)
  # create new meeting schedules for a location
  # get meetings for a location
  # get a meeting calendar for a location
  #
  # TODO
  # setup holidays
  # query holidays
  # get a holiday calendar

  # Also used by other sub-systems to
  # Setup calendar

  # Expect to use the following lightweight objects
  # MeetingInfo
  # MeetingScheduleInfo

  attr_reader :user, :created_at

  def initialize(user)
    @user = user; @created_at = DateTime.now
  end

  # This returns a meeting for the given location on the date,
  # or nil if there is none currently scheduled
  def get_meeting(for_location, on_date = Date.today)
    MeetingCalendar.meeting_at_location_on_date(for_location, on_date)
  end
  
  # This returns a series of meetings for the location commencing on or after 
  # the specified date, and an empty list when there are none
  def get_meeting_calendar(for_location, from_date = Date.today, till_date = from_date + DEFAULT_FUTURE_MAX_DURATION_IN_DAYS)
    MeetingCalendar.meeting_calendar(for_location, from_date, till_date)
  end

  def setup_meeting_calendar(on_date)
    MeetingCalendar.setup_calendar(on_date)
  end

  # Creates a new meeting schedule for the given location
  def setup_meeting_schedule(for_location, meeting_schedule_info)
    #TBD
  end

  # Gets meeting schedules in effect for the given location
  def get_meeting_schedules(for_location)
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
