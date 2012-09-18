class MeetingFacade < StandardFacade
  include Constants::Time

  # Use the facade to:
  # get meeting schedules for a location (Center)
  # create new meeting schedules for a location
  # get meetings for a location
  # get a meeting calendar for a location from the meeting calendar
  # get meetings as per the current meeting schedule for a location
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
  
  ##################
  ## QUERIES       #
  ##################

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

  # Returns the next meeting for the location after the specified date, if one has been generated using the meeting calendar
  def get_next_meeting(for_location, after_date)
    MeetingCalendar.next_meeting_for_location(for_location, after_date)
  end

  # Returns the previous meeting for the location before the specified date, if one has been generated using the meeting calendar
  def get_previous_meeting(for_location, before_date)
    MeetingCalendar.previous_meeting_for_location(for_location, before_date)
  end

  # Gets meeting schedules in effect for the given location
  def get_meeting_schedules(for_location)
    MeetingScheduleManager.get_all_meeting_schedule_infos(for_location)
  end

  # Returns a simple list of meeting dates as per the meeting schedule, or nil if there are no meeting schedules for the location
  # REMEMBER these are not as per the meeting calendar and therefore, there is no guarantee about their conduct
  def get_meetings_per_schedule(for_location, from_date = Date.today, till_date = from_date + DEFAULT_FUTURE_MAX_DURATION_IN_DAYS)
    MeetingScheduleManager.get_meetings_per_schedule(for_location, from_date, till_date)
  end

  # Get a data structure that has IDs for locations meeting on
  # the date as per the meeting calendar, including both proposed and confirmed
  # meetings
  def get_locations_meeting_on_date(on_date = Date.today)
    MeetingCalendar.all_locations_meeting_on_date(on_date)
  end

  def get_meetings_for_loncations_on_date(locations = [], on_date = Date.today)
    locations.collect{|location| get_meeting(location, on_date)}.compact
  end

  # Get a data structure that has IDs for locations that have CONFIRMED meetings
  # on a given date
  def get_locations_confirmed_meeting_on_date(on_date = Date.today)
    MeetingCalendar.all_locations_meeting_on_date(on_date, Constants::Space::CONFIRMED_MEETING_STATUS)
  end

  # Get a data structure that has IDs for locations that have PROPOSED meetings
  # on a given date
  def get_locations_proposed_meeting_on_date(on_date = Date.today)
    MeetingCalendar.all_locations_meeting_on_date(on_date, Constants::Space::PROPOSED_MEETING_STATUS)
  end

  def get_accomodated_frequencies(at_location, on_date)
    all_loan_frequencies = MarkerInterfaces::Recurrence::FREQUENCIES
    MarkerInterfaces::Recurrence.accomodated_frequencies(all_loan_frequencies)
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

  ##################
  ## UPDATES       #
  ##################

  # Creates a new meeting schedule for the given location
  def setup_meeting_schedule(for_location, meeting_schedule_info)
    MeetingScheduleManager.create_meeting_schedule(for_location, meeting_schedule_info)
  end

  # Creates a holiday at the location as specified
  def setup_holiday(for_location, holiday_info)
    #TBD
  end

  # This setups a calendar with meetings after consulting meeting schedules
  # and TODO: after consulting holiday schedules
  def setup_meeting_calendar(on_date)
    location_facade = FacadeFactory.instance.get_other_facade(FacadeFactory::LOCATION_FACADE, self)
    for_locations = location_facade.all_locations_that_can_meet
    for_locations_and_schedules = MeetingScheduleManager.get_all_meeting_schedules_on_date(on_date, for_locations)
    MeetingCalendar.setup_calendar(on_date, for_locations_and_schedules)
  end

  def setup_meeting_calendar_for_location(location, begion_date, number_of_days)
    1.upto(number_of_days) do |count|
      begion_date += 1
      for_locations_and_schedules = MeetingScheduleManager.get_all_meeting_schedules_on_date(begion_date, [location])
      MeetingCalendar.setup_calendar(begion_date, for_locations_and_schedules)
    end
  end

end