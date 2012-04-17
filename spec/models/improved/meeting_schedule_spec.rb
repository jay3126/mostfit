require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

# Utility that populates an array with dates given a date range and a frequency
def populate_dates(begin_date, upto_but_not_including_date, frequency = 1)
  dates = []

  on_date = begin_date
  while on_date < upto_but_not_including_date
    dates << on_date
    on_date += frequency
  end
  dates
end

describe MeetingScheduleInfo do

  before(:all) do
    @meeting_schedule_infos = []
    @some_numbers = [28, 26, 11 , 23, 17, 19]
    @some_dates = @some_numbers.collect { |num| Date.parse("2012-04-#{num}") }
    @some_dates.each { |date|
      @meeting_schedule_infos.push(
        MeetingSchedule.new(:schedule_begins_on => date, :meeting_frequency => Constants::Time::WEEKLY,
          :meeting_time_begins_hours => 12, :meeting_time_begins_minutes => 20).to_info)
    }
  end

  it "should be sorted most recent first" do
    sorted_dates = @some_dates.sort.reverse
    sorted_schedules = @meeting_schedule_infos.sort
    sorted_schedules.each_with_index { |ms, idx|
      ms.schedule_begins_on.should == sorted_dates[idx]
    }
  end

end

describe MeetingSchedule do

  before(:all) do
    @first_schedule_begins = Date.parse("01-01-2011")
    @first_meeting_time_begins_hours = 11; @first_meeting_time_begins_minutes = 23

    @second_schedule_begins = Date.parse("27-06-2011")
    @second_meeting_time_begins_hours = 7; @second_meeting_time_begins_minutes = 34

    @first_schedule_dates_range = populate_dates(@first_schedule_begins, @second_schedule_begins)
    @second_schedule_dates_range = populate_dates(@second_schedule_begins, (@second_schedule_begins + Constants::Time::DEFAULT_FUTURE_MAX_DURATION_IN_DAYS))

    @weekly_first = MeetingSchedule.new(
      :meeting_frequency => Constants::Time::WEEKLY,
      :schedule_begins_on => @first_schedule_begins,
      :meeting_time_begins_hours => @first_meeting_time_begins_hours, :meeting_time_begins_minutes => @first_meeting_time_begins_minutes
    )

    @weekly_second = MeetingSchedule.new(
      :meeting_frequency => Constants::Time::WEEKLY,
      :schedule_begins_on => @second_schedule_begins,
      :meeting_time_begins_hours => @second_meeting_time_begins_hours, :meeting_time_begins_minutes => @second_meeting_time_begins_minutes
    )

    @biweekly_first = MeetingSchedule.new(
      :meeting_frequency => Constants::Time::BIWEEKLY,
      :schedule_begins_on => @first_schedule_begins,
      :meeting_time_begins_hours => @first_meeting_time_begins_hours, :meeting_time_begins_minutes => @first_meeting_time_begins_minutes
    )

    @biweekly_second = MeetingSchedule.new(
      :meeting_frequency => Constants::Time::BIWEEKLY,
      :schedule_begins_on => @second_schedule_begins,
      :meeting_time_begins_hours => @second_meeting_time_begins_hours, :meeting_time_begins_minutes => @second_meeting_time_begins_minutes
    )

  end

  it "should indicate a meeting date on meeting days per weekly frequency" do
    first_schedule_meeting_dates = populate_dates(@first_schedule_begins, @second_schedule_begins, 7)
    second_schedule_meeting_dates = populate_dates(@second_schedule_begins, (@second_schedule_begins + Constants::Time::DEFAULT_FUTURE_MAX_DURATION_IN_DAYS), 7)

    @first_schedule_dates_range.each { |on_date|
      meeting_scheduled = @weekly_first.is_proposed_scheduled_on_date?(on_date)
      if first_schedule_meeting_dates.include?(on_date)
        meeting_scheduled.should == true #meets on these days
      else
        meeting_scheduled.should == false #no meeting on other days
      end
    }

    @second_schedule_dates_range.each { |on_date|
      meeting_scheduled = @weekly_second.is_proposed_scheduled_on_date?(on_date)
      if second_schedule_meeting_dates.include?(on_date)
        meeting_scheduled.should == true
      else
        meeting_scheduled.should == false
      end
    }
  end

  it "should indicate a meeting date on meeting days per biweekly frequency" do
    first_schedule_meeting_dates = populate_dates(@first_schedule_begins, @second_schedule_begins, 14)
    second_schedule_meeting_dates = populate_dates(@second_schedule_begins, (@second_schedule_begins + Constants::Time::DEFAULT_FUTURE_MAX_DURATION_IN_DAYS), 14)

    @first_schedule_dates_range.each { |on_date|
      meeting_scheduled = @biweekly_first.is_proposed_scheduled_on_date?(on_date)
      if first_schedule_meeting_dates.include?(on_date)
        meeting_scheduled.should == true #meets on these days
      else
        meeting_scheduled.should == false #no meeting on other days
      end
    }

    @second_schedule_dates_range.each { |on_date|
      meeting_scheduled = @biweekly_second.is_proposed_scheduled_on_date?(on_date)
      if second_schedule_meeting_dates.include?(on_date)
        meeting_scheduled.should == true
      else
        meeting_scheduled.should == false
      end
    }
  end
  
  it "should not indicate a meeting date if the date is before the beginning of the meeting schedule" do
    first_earlier_date = @first_schedule_begins - 3
    @weekly_first.is_proposed_scheduled_on_date?(first_earlier_date).should == false

    second_earlier_date = @second_schedule_begins - 7
    @weekly_second.is_proposed_scheduled_on_date?(second_earlier_date).should == false
  end

end
