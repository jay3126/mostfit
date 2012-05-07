class MeetingScheduleManager
  include Constants::Time

  # Intermediates in creating and managing the relationship between locations
  # and schedules

  # Creates a new meeting schedule for the location
  def self.create_meeting_schedule(for_location, meeting_schedule_info)
    validity_result = MeetingSchedule.validate_new_meeting_schedule(for_location, meeting_schedule_info)
    is_valid = validity_result.is_a?(Array) ? validity_result.first : validity_result
    raise Errors::BusinessValidationError, validity_result.last unless is_valid
    meeting_schedule = MeetingSchedule.record_meeting_schedule(meeting_schedule_info)
    for_location.save_meeting_schedule(meeting_schedule)
  end

  # Returns a series of dates which are the scheduled meeting dates
  # as per the meeting schedules for the location
  def self.get_meetings_per_schedule(for_location, on_or_after_date = Date.today, until_date = on_or_after_date + DEFAULT_FUTURE_MAX_DURATION_IN_DAYS)
    meeting_schedules = get_all_meeting_schedules(for_location)
    return nil unless (meeting_schedules and (not (meeting_schedules.empty?)))
    earliest_meeting_schedules = meeting_schedules.sort.reverse
    next_schedule_begin_dates = []

    earliest_meeting_schedules.each_with_index { |ms, idx|
      next if idx == 0
      next_schedule_begin_dates.push(ms.from_date)
    }
    next_schedule_begin_dates.push(until_date)

    meetings_per_schedule = []
    earliest_meeting_schedules.each_with_index { |ms, idx|
      before_date = next_schedule_begin_dates[idx]
      meetings_per_schedule += ms.all_meeting_dates_in_schedule(before_date)
    }
    DateValidator.screen_dates(meetings_per_schedule, on_or_after_date, until_date)
  end

  # Returns the meeting schedules for the location
  def self.get_all_meeting_schedule_infos(for_location)
    get_all_meeting_schedules(for_location).collect {|ms| ms.to_info}
  end
  
  # Gets all meeting schedules in effect on a given date
  def self.get_all_meeting_schedules_on_date(on_date, for_locations)
    current_meeting_schedules = {}
    for_locations.each { |location_type, location_instances|
      location_ids_and_schedules = {}
      location_instances.each { |location|
        schedule_effective = location.meeting_schedule_effective(on_date)
        location_ids_and_schedules[location.id] = schedule_effective if schedule_effective
      }
      current_meeting_schedules[location_type] = location_ids_and_schedules
    }
    current_meeting_schedules
  end

  # Returns a list of frequencies that can be accomodated at the center
  #
  # TBD: the list of accomocated frequencies is sensitive to the point in time,
  # since the meeting schedule frequency can change, but for now,
  # we are defaulting this to the current date
  def self.accomodated_frequencies(loan_frequencies, on_date = Date.today)
    
  end

  private

  # Returns the meeting schedules for the location
  def self.get_all_meeting_schedules(for_location)
    for_location.meeting_schedules
  end
  
end

class MeetingScheduleInfo
  include IsMeeting
  include Comparable
  include MarkerInterfaces::Recurrence

  # sorted most recent first by the schedule begin date
  def <=>(other)
    other.respond_to?(:schedule_begins_on) ?
      other.schedule_begins_on <=> self.schedule_begins_on : nil
  end

  attr_reader :meeting_frequency, :schedule_begins_on, :meeting_time_begins_hours, :meeting_time_begins_minutes

  def initialize(meeting_frequency, schedule_begins_on, meeting_time_begins_hours, meeting_time_begins_minutes)
    @meeting_frequency = meeting_frequency
    @schedule_begins_on = schedule_begins_on
    @meeting_time_begins_hours = meeting_time_begins_hours; @meeting_time_begins_minutes = meeting_time_begins_minutes
  end

  def to_s
    "Meeting schedule with frequency #{self.meeting_frequency} effective #{self.schedule_begins_on} at #{self.meeting_begins_at}"
  end

  def from_date; @schedule_begins_on; end

  # implements MarkerInterfaces::Recurrence#frequency
  def frequency; @meeting_frequency; end
  
end

class MeetingSchedule
  include DataMapper::Resource
  include Constants::Time
  include IsMeeting
  include MarkerInterfaces::Recurrence

  property :id,                         Serial
  property :meeting_frequency,          Enum.send('[]', *MEETING_FREQUENCIES), :nullable => false
  property :meeting_weekday,            Enum.send('[]', *DAYS_OF_THE_WEEK), :nullable => false,
    :default => lambda { |obj, p| Constants::Time.get_week_day(obj.schedule_begins_on) }
  property :schedule_begins_on,         Date, :nullable => false
  property :meeting_time_begins_hours,  Integer, :min => EARLIEST_MEETING_HOURS_ALLOWED, :max => LATEST_MEETING_HOURS_ALLOWED
  property :meeting_time_begins_minutes,Integer, :min => EARLIEST_MEETING_MINUTES_ALLOWED, :max => LATEST_MEETING_MINUTES_ALLOWED

  has n, :centers, :through => Resource
  
  # getters added for conventional access
  def from_date; self.schedule_begins_on; end
  def frequency; self.meeting_frequency; end

  def self.validate_new_meeting_schedule(for_location, meeting_schedule_info)
    existing_meeting_schedules = for_location.meeting_schedules
    return true if existing_meeting_schedules.empty?
    most_recent_schedule = existing_meeting_schedules.sort.first
    most_recent_schedule_date = most_recent_schedule.schedule_begins_on
    most_recent_schedule_date < meeting_schedule_info.schedule_begins_on ? true :
       [false, "A new meeting schedule can only begin after #{most_recent_schedule_date} for the specified location #{for_location.name}"]
  end

  def to_info
    MeetingScheduleInfo.new(meeting_frequency, schedule_begins_on, meeting_time_begins_hours, meeting_time_begins_minutes)
  end
  
  def self.from_info(meeting_schedule_info)
    my_attributes = {}
    my_attributes[:meeting_frequency] = meeting_schedule_info.meeting_frequency
    my_attributes[:schedule_begins_on] = meeting_schedule_info.schedule_begins_on
    my_attributes[:meeting_time_begins_hours] = meeting_schedule_info.meeting_time_begins_hours
    my_attributes[:meeting_time_begins_minutes] = meeting_schedule_info.meeting_time_begins_minutes
    new(my_attributes)
  end

  def self.record_meeting_schedule(meeting_schedule_info)
    meeting_schedule = from_info(meeting_schedule_info)
    was_saved = meeting_schedule.save
    raise Errors::DataError, "Meeting schedule was not saved: #{meeting_schedule.errors.first.first}" unless was_saved
    meeting_schedule
  end

  def to_s
    "Meeting schedule with frequency #{self.meeting_frequency} effective #{self.schedule_begins_on} at #{self.meeting_begins_at}"
  end

  def <=>(other)
    other.respond_to?(:schedule_begins_on) ?
      other.schedule_begins_on <=> self.schedule_begins_on : nil
  end

  # query this method for whether a meeting is scheduled on the date
  # as per the meeting frequency for this meeting schedule
  def is_proposed_scheduled_on_date?(on_date)
    return false if on_date < self.schedule_begins_on
    occurs_on_meeting_frequency?(on_date)
  end

  # Returns all of the dates that meetings will be scheduled as per the frequency of meetings
  def all_meeting_dates_in_schedule(before_date)
    all_dates = []
    date = self.schedule_begins_on
    while date < before_date
      all_dates << date if is_proposed_scheduled_on_date?(date)
      date += 1
    end
    all_dates
  end

  # returns a number in days for the meeting frequency
  # not all meeting frequencies have a frequency in days
  # for e.g., monthly does not have a regular 'frequency'
  def frequency_in_days
    MEETING_FREQUENCIES_AS_DAYS[self.meeting_frequency]
  end

  private

  # Given a date, this checks whether it falls on a meeting day
  def occurs_on_meeting_frequency?(on_date)
    return (on_date.day == self.schedule_begins_on.day) if self.meeting_frequency == MarkerInterfaces::Recurrence::MONTHLY
    date_difference = on_date - self.schedule_begins_on
    return (date_difference % frequency_in_days == 0)
  end

end