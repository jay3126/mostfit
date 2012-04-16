class MeetingScheduleInfo
  include IsMeeting

  attr_reader :meeting_frequency, :schedule_begins_on, :meeting_time_begins_hours, :meeting_time_begins_minutes

  def initialize(meeting_frequency, schedule_begins_on, meeting_time_begins_hours, meeting_time_begins_minutes)
    @meeting_frequency = meeting_frequency
    @schedule_begins_on = schedule_begins_on
    @meeting_time_begins_hours = meeting_time_begins_hours; @meeting_time_begins_minutes = meeting_time_begins_minutes
  end

  def to_s
    "Meeting schedule with frequency #{self.meeting_frequency} effective #{self.schedule_begins_on} at #{self.meeting_begins_at}"
  end
  
end

class MeetingSchedule
  include DataMapper::Resource
  include Constants::Time
  include IsMeeting

  property :id,                         Serial
  property :meeting_frequency,          Enum.send('[]', *MEETING_FREQUENCIES), :nullable => false
  property :meeting_weekday,            Enum.send('[]', *DAYS_OF_THE_WEEK), :nullable => false, :default => lambda { |obj, p| Constants::Time.get_week_day(obj.schedule_begins_on) }
  property :schedule_begins_on,         Date, :nullable => false
  property :meeting_time_begins_hours,  Integer, :min => EARLIEST_MEETING_HOURS_ALLOWED, :max => LATEST_MEETING_HOURS_ALLOWED
  property :meeting_time_begins_minutes,Integer, :min => EARLIEST_MEETING_MINUTES_ALLOWED, :max => LATEST_MEETING_MINUTES_ALLOWED

  has n, :centers, :through => Resource
  
  # getters added for conventional access
  def from_date; self.schedule_begins_on; end

  def to_info
    MeetingScheduleInfo.new(meeting_frequency, schedule_begins_on, meeting_time_begins_hours, meeting_time_begins_minutes)
  end

  def to_s
    "Meeting schedule with frequency #{self.meeting_frequency} effective #{self.schedule_begins_on} at #{self.meeting_begins_at}"
  end

  # query this method for whether a meeting is scheduled on the date
  # as per the meeting frequency for this meeting schedule
  def is_proposed_scheduled_on_date?(on_date)
    return false if on_date < @schedule_begins_on
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
    return (on_date.day == self.schedule_begins_on.day) if self.meeting_frequency == MONTHLY
    date_difference = on_date - self.schedule_begins_on
    return (date_difference % frequency_in_days == 0)
  end

end