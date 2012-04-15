# For anything that is a meeting, this module provides utility methods
module IsMeeting
  include Comparable

  # When a meeting_time_begins_hours and meeting_time_begins_minutes is present,
  # returns a meeting time begins as just minutes
  def meeting_begins_at_in_minutes
    begins_minutes = (self.respond_to?(:meeting_time_begins_minutes) and self.meeting_time_begins_minutes) ?
      self.meeting_time_begins_minutes : 0
    begins_hours = (self.respond_to?(:meeting_time_begins_hours) and self.meeting_time_begins_hours) ?
      self.meeting_time_begins_hours : 0
    (begins_hours * 60) + begins_minutes
  end

  # Formats the meeting_begins_at_in_minutes in the common formats
  def meeting_begins_at(format = Constants::Time::DEFAULT_MEETING_TIME_FORMAT)
    raise ArgumentError, "Unrecognised meeting time format: #{format}" unless Constants::Time::TIME_FORMATS.include?(format)

    total_minutes = meeting_begins_at_in_minutes
    total_hours = (total_minutes / 60).to_i
    minutes = total_minutes - (total_hours * 60)
    am_pm_suffix = ""

    hours = total_hours if format == Constants::Time::TWENTY_FOUR_HOUR_FORMAT
    
    if format == Constants::Time::TWELVE_HOUR_FORMAT
      hours, am_pm_suffix = (total_hours > 12 ? [total_hours - 12, ' PM'] : [total_hours, ' AM'])
    end

    "#{hours.to_s.rjust(2,'0')}:#{minutes.to_s.rjust(2, '0')}#{am_pm_suffix}"
  end

  # Sort by meeting time in minutes
  def <=>(other)
    other.respond_to?(:meeting_begins_at_in_minutes) ?
      self.meeting_begins_at_in_minutes <=> other.meeting_begins_at_in_minutes : nil
  end

end