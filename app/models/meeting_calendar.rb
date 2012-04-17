class MeetingInfo
  include IsMeeting

  # Is a light-weight read-only object that provides meeting information

  attr_reader :location_type, :location_id, :on_date, :meeting_status, :meeting_time_begins_hours, :meeting_time_begins_minutes

  def initialize(location_type, location_id, on_date, meeting_status, meeting_time_begins_hours, meeting_time_begins_minutes)
    @location_type = location_type; @location_id = location_id
    @on_date = on_date
    @meeting_status = meeting_status
    @meeting_time_begins_hours = meeting_time_begins_hours; @meeting_time_begins_minutes = meeting_time_begins_minutes
  end

  def to_s
    "Meeting at #{location_type} (#{location_id}) on #{on_date} at #{meeting_begins_at}"
  end

end

class MeetingCalendar
  include DataMapper::Resource
  include Constants::Time
  include Constants::Space
  include IsMeeting

  # The meeting calendar consults meeting schedules for all locations that meet
  # It then periodically creates a 'proposed' meeting calendar based on such schedules
  # Every time it is updated, it checks for new meeting schedules, new holidays, and changes of business day for the desired future duration
  # In such event, it either confirms the proposed meeting schedule as the confirmed meeting schedule or re-schedules the same
  # All locations that meet merely consult the meeting calendar for the proposed and the actual calendar

  property :id,                         Serial
  property :location_type,              Enum.send('[]', *MEETINGS_SUPPORTED_AT), :nullable => false
  property :location_id,                Integer, :nullable => false
  property :on_date,                    Date, :nullable => false
  property :meeting_status,             Enum.send('[]', *MEETING_SCHEDULE_STATUSES), :nullable => false, :default => PROPOSED_MEETING_STATUS
  property :meeting_time_begins_hours,  Integer, :min => EARLIEST_MEETING_HOURS_ALLOWED, :max => LATEST_MEETING_HOURS_ALLOWED
  property :meeting_time_begins_minutes,Integer, :min => EARLIEST_MEETING_MINUTES_ALLOWED, :max => LATEST_MEETING_MINUTES_ALLOWED

  # Returns an instance of MeetingInfo
  def to_info
    MeetingInfo.new(location_type, location_id, on_date, meeting_status, meeting_time_begins_hours, meeting_time_begins_minutes)
  end

  # Creates a meeting for the specified location and date
  def self.setup_meeting(location, on_date, meeting_status, meeting_time_begins_hours, meeting_time_begins_minutes)
    query = predicates_for_location(location)
    query.merge!(
      :on_date => on_date,
      :meeting_status => meeting_status,
      :meeting_time_begins_hours => meeting_time_begins_hours,
      :meeting_time_begins_minutes => meeting_time_begins_minutes
    )
    first_or_create(query)
  end

  # Returns whether a location is meeting on a given date
  def self.confirmed_meeting_on_date?(location, on_date = Date.today)
    not (meeting_at_location_on_date(location, on_date, CONFIRMED_MEETING_STATUS).nil?)
  end

  def self.proposed_meeting_on_date?(location, on_date = Date.today)
    not (meeting_at_location_on_date(location, on_date, PROPOSED_MEETING_STATUS).nil?)
  end

  # Gets meeting information for a given location on specified date
  def self.meeting_at_location_on_date(location, on_date = Date.today, meeting_status = nil)
    meeting = find_by_instance_on_date(location, on_date, meeting_status)
    meeting ? meeting.to_info : nil
  end

  # Returns a series of meetings for the given location beginning on or after the from_date
  # and extending upto or including the till_date, which (when not specified) is defaulted by adding a constant number of days
  # to the from_date
  def self.confirmed_meeting_calendar(location, from_date = Date.today, till_date = from_date + DEFAULT_FUTURE_MAX_DURATION_IN_DAYS)
    meetings_for_location(location, from_date, till_date, CONFIRMED_MEETING_STATUS).collect {|meeting| meeting.to_info}
  end

  def self.proposed_meeting_calendar(location, from_date = Date.today, till_date = from_date + DEFAULT_FUTURE_MAX_DURATION_IN_DAYS)
    meetings_for_location(location, from_date, till_date, PROPOSED_MEETING_STATUS).collect {|meeting| meeting.to_info}
  end

  def self.meeting_calendar(location, from_date = Date.today, till_date = from_date + DEFAULT_FUTURE_MAX_DURATION_IN_DAYS)
    meetings_for_location(location, from_date, till_date)
  end

  # When invoked, consults a location facade for meeting schedules,
  # then creates meetings for any locations on the date
  def self.setup_calendar(on_date)
    locations_and_schedules = LocationFacade.new.all_location_meeting_schedules(on_date)
    locations_and_meetings = {}
    locations_and_schedules.each { |location_type, schedule_map|
      meeting_map = {}
      schedule_map.each { |id, meeting_schedule|
        meeting_map[id] = meeting_schedule if meeting_schedule.is_proposed_scheduled_on_date?(on_date)
      }
      locations_and_meetings[location_type] = meeting_map
    }
    setup(locations_and_meetings, on_date)
  end

  private

  # Test for whether a holiday is in force for the specified location on a given date
  def self.get_holiday(at_location, on_date)
    #TBD
  end

  # Test for a business day on the date
  def self.check_business_day(on_date)
    ConfigurationFacade.instance.is_business_day?(on_date)
  end

  # Given a map of location types and meetings for the locations at those location types,
  # creates meetings in the meeting calendar
  def self.setup(locations_and_meetings, on_date)
    locations_and_meetings.each { |location_type, meeting_map|
      meeting_map.each { |location_id, meeting| 
        first_or_create(
          :on_date => on_date,
          :location_type => location_type,
          :location_id => location_id,
          :meeting_status => PROPOSED_MEETING_STATUS,
          :meeting_time_begins_hours => meeting.meeting_time_begins_hours,
          :meeting_time_begins_minutes => meeting.meeting_time_begins_minutes
        )
      }
    }
  end

  # Returns the first meeting for a location on a given date
  def self.find_by_instance_on_date(location, on_date, meeting_status)
    query = predicates_for_location(location)
    query.merge!(:on_date => on_date)
    query.merge!(:meeting_status => meeting_status) if meeting_status
    first(query)
  end

  # Returns all meetings for a location in the date range specified
  def self.meetings_for_location(location, from_date, till_date, meeting_status = nil)
    query = predicates_for_location(location)
    query.merge!(predicates_for_date_range(from_date, till_date))
    query.merge!(:meeting_status => meeting_status) if meeting_status
    all(query)
  end

  def self.predicates_for_location(location)
    location_type_string, location_id = Resolver.resolve_location(location)
    raise ArgumentError, "meetings are not supported at #{location_type_string}" unless
    (location_type_string and Constants::Space::MEETINGS_SUPPORTED_AT.include?(location_type_string))
    raise ArgumentError, "a location id was not specified" unless location_id
    {:location_type => location_type_string, :location_id => location_id }
  end

  # Returns a hash with query parameters that restrict the search on meetings to the date range specified
  def self.predicates_for_date_range(from_date, to_date)
    raise ArgumentError, "from date is not valid: #{from_date}" unless from_date
    raise ArgumentError, "to date is not valid: #{to_date}" unless to_date
    raise ArgumentError, "from date should precede to date" if to_date < from_date
    {:on_date.gte => from_date, :on_date.lt => to_date, :order => [:on_date.asc]}
  end

 end