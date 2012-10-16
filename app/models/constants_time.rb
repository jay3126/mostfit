module Constants
  module Time

    # points in time

    MEETING_FREQUENCIES         =
      [MarkerInterfaces::Recurrence::DAILY, MarkerInterfaces::Recurrence::WEEKLY, MarkerInterfaces::Recurrence::BIWEEKLY, MarkerInterfaces::Recurrence::MONTHLY]
    MEETING_FREQUENCIES_AS_DAYS =
      { MarkerInterfaces::Recurrence::DAILY => 1, MarkerInterfaces::Recurrence::WEEKLY => 7, MarkerInterfaces::Recurrence::BIWEEKLY => 14 }

    EARLIEST_MEETING_HOURS_ALLOWED      = 0; LATEST_MEETING_HOURS_ALLOWED = 23
    MEETING_HOURS_PERMISSIBLE_RANGE     = Range.new(EARLIEST_MEETING_HOURS_ALLOWED, LATEST_MEETING_HOURS_ALLOWED)
    EARLIEST_MEETING_MINUTES_ALLOWED    = 0; LATEST_MEETING_MINUTES_ALLOWED = 59
    MEETING_MINUTES_PERMISSIBLE_RANGE   = Range.new(EARLIEST_MEETING_MINUTES_ALLOWED, LATEST_MEETING_MINUTES_ALLOWED)
    DEFAULT_PAST_MAX_DURATION_IN_DAYS   = 90
    DEFAULT_FUTURE_MAX_DURATION_IN_DAYS = 366

    SUNDAY           = :sunday; MONDAY = :monday; TUESDAY = :tuesday; WEDNESDAY = :wednesday; THURSDAY = :thursday; FRIDAY = :friday; SATURDAY = :saturday
    DAYS_OF_THE_WEEK = [SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY]

    MONTHLY_MEETING_DATE_LIMIT = 28

    TWELVE_HOUR_FORMAT          = :am_pm_format; TWENTY_FOUR_HOUR_FORMAT = :twenty_four_hour_format
    DEFAULT_MEETING_TIME_FORMAT = TWELVE_HOUR_FORMAT
    TIME_FORMATS                = [TWELVE_HOUR_FORMAT, TWENTY_FOUR_HOUR_FORMAT]

    EARLIEST_DATE_OF_OPERATION = Date.parse('2009-01-01')

    EARLIEST_BUSINESS_DATE_EACH_MONTH = 1
    LAST_BUSINESS_DATE_EACH_MONTH = 26

    # Returns the constant in the application for the day of the week
    def self.get_week_day(on_date)
      DAYS_OF_THE_WEEK[on_date.wday]
    end

    def self.get_next_date_for_day(weekday, on_or_after_date)
      raise ArgumentError, "Weekday not recognized: #{weekday}" unless DAYS_OF_THE_WEEK.include?(weekday)
      on_or_after_weekday = get_week_day(on_or_after_date)
      return on_or_after_date if on_or_after_weekday == weekday
      weekday_difference = DAYS_OF_THE_WEEK.index(weekday) - DAYS_OF_THE_WEEK.index(on_or_after_weekday)
      weekday_difference > 0 ? on_or_after_date + weekday_difference : on_or_after_date + (7 - weekday_difference.abs)
    end

    # Gets the date for the immediately preceding Sunday (or today if today is Sunday)
    def self.get_beginning_sunday(for_date)
      for_date - (for_date.wday)
    end

    # Gets a list of dates for the current week beginning with the immediately preceding Sunday
    def self.get_current_week_dates(for_date)
      sunday = get_beginning_sunday(for_date)
      0.upto(6).collect { |day| sunday + day }
    end

    # Returns the date in the next month with the same 'date' of the month as the specified date
    def self.get_next_month_date(for_date)
      next_month_month, next_month_year = for_date.mon == 12 ? [1, for_date.year + 1] : [for_date.mon + 1, for_date.year]
      Date.new(next_month_year, next_month_month, for_date.day)
    end

    def self.is_first_day_of_month?(some_date); some_date.day == 1; end

    def self.is_last_day_of_month?(some_date)
      is_first_day_of_month?(some_date + 1)
    end

    # Returns the next date as per the specified date incremented by the frequency
    def self.get_next_date(from_date, frequency)
      if frequency == MarkerInterfaces::Recurrence::MONTHLY
        raise ArgumentError, "Date cannot be after the #{MONTHLY_MEETING_DATE_LIMIT} for monthly frequency" if from_date.day > MONTHLY_MEETING_DATE_LIMIT
        date = get_next_month_date(from_date)
      else
        number_of_days = MEETING_FREQUENCIES_AS_DAYS[frequency]
        date = from_date + number_of_days
      end
      custom_date = CustomCalendar.first(:collection_date => date)
      custom_move_date = custom_date.blank? ? '' : custom_date.on_date
      custom_move_date.blank? ? date : custom_move_date
    end

    def self.ordered_dates(from_date, to_date)
      [from_date, to_date].sort
    end

    # Finds the date from the series of dates that immediately precedes the
    # specified date
    # If this date is on the series of dates, it returns the same date and not an earlier date
    # @param [Date] for_date
    # @param [Array] from_dates
    def self.get_immediately_earlier_date(for_date, *from_dates)
      return for_date if from_dates.include?(for_date)

      earliest_date = from_dates.sort.first
      return nil if for_date < earliest_date

      checked_past_date = nil
      from_dates.sort.each { |next_date|
        break if next_date > for_date
        checked_past_date = next_date
      }
      checked_past_date
    end

    # Finds the date from the series of dates that immediately follows the
    # specified date
    # If this date is on the series of dates, it returns the same date and not a later date
    def self.get_immediately_next_date(for_date, *from_dates)
      return for_date if from_dates.include?(for_date)

      latest_date = from_dates.sort.last
      return nil if latest_date < for_date

      checked_later_date = nil
      from_dates.sort.reverse.each { |next_date|
        break if next_date < for_date
        checked_later_date = next_date
      }
      checked_later_date
    end

  end
end