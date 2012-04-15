require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe MeetingCalendar do

  before(:all) do

    @first_starting_sunday = Date.parse("2012-01-01")
    @first_ending_saturday = Date.parse("2012-01-14")
    @first_meeting_time_begins_hours, @first_meeting_time_begins_minutes = 10, 20
    @first_date_range = @first_starting_sunday..@first_ending_saturday

    @second_starting_sunday = Date.parse("2012-01-15")
    @second_ending_saturday = Date.parse("2012-01-28")

    @weekly_centers = {}
    Constants::Time::DAYS_OF_THE_WEEK.each { |day|
      @weekly_centers[day] = Factory(:center)
    }

    @schedule_begin_dates = {}
    begin_date = @first_starting_sunday
    Constants::Time::DAYS_OF_THE_WEEK.each { |day|
      begin_date += 1 unless (day == Constants::Time::SUNDAY)
      @schedule_begin_dates[day] = begin_date
    }

    @weekly_centers.keys.each { |day|
      center = @weekly_centers[day]
      schedule_begin_date = @schedule_begin_dates[day]
      ms = MeetingSchedule.create(:meeting_frequency => :weekly, :schedule_begins_on => schedule_begin_date,
        :meeting_time_begins_hours => @first_meeting_time_begins_hours, :meeting_time_begins_minutes => @first_meeting_time_begins_minutes)
      center.meeting_schedules << ms
      center.save
    }

    @first_date_range.each {|on_date| MeetingCalendar.setup_calendar(on_date)}
    
  end

  it "should return a proposed meeting calendar for a location as per multiple meeting schedules"

  it "should return the correct proposed meeting calendar for a location as per a single weekly meeting schedule for a given date range" do
    @first_date_range.each {|on_date|
      on_weekday = Constants::Time.get_week_day(on_date)
      @weekly_centers.each { |day, center|
        center_has_meeting_on_date = MeetingCalendar.proposed_meeting_on_date?(center, on_date)
        #false if the day of the week is not a meeting day, and true otherwise for each center throughout the date range
        center_has_meeting_on_date.should == (on_weekday == day)
      }
    }
  end

end