require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe MeetingScheduleManager do

  before(:each) do
    @center = Factory(:center)
    @first_msi = MeetingScheduleInfo.new(Constants::Time::WEEKLY, Date.parse('2012-01-05'), 10, 20)
    @second_msi = MeetingScheduleInfo.new(Constants::Time::MONTHLY, Date.parse('2012-01-26'), 10, 20)
    @third_msi = MeetingScheduleInfo.new(Constants::Time::BIWEEKLY, Date.parse('2012-03-28'), 10, 20)
    @fourth_msi = MeetingScheduleInfo.new(Constants::Time::DAILY, Date.parse('2012-05-23'), 10, 20)
  end

  it "should return nil for meetings by schedule if a location does not have any meeting schedules" do
    MeetingScheduleManager.get_meetings_per_schedule(@center).should be_nil
  end

  it "should save meeting schedules for a center as requested" do
    MeetingScheduleManager.create_meeting_schedule(@center, @first_msi)
    MeetingScheduleManager.create_meeting_schedule(@center, @second_msi)
    MeetingScheduleManager.create_meeting_schedule(@center, @third_msi)

    MeetingScheduleManager.get_all_meeting_schedule_infos(@center).sort.should ==
      [@third_msi, @second_msi, @first_msi]
  end

  it "should raise an Errors::DataError if it is unable to save a meeting schedule for the location" do
    broken_msi = MeetingScheduleInfo.new(nil, Date.today, 10, 35)
    lambda {MeetingScheduleManager.create_meeting_schedule(@center, broken_msi)}.should raise_error(Errors::DataError)
  end

  it "should return the meeting dates as per multiple schedules as expected" do
    MeetingScheduleManager.create_meeting_schedule(@center, @first_msi)
    MeetingScheduleManager.create_meeting_schedule(@center, @second_msi)
    MeetingScheduleManager.create_meeting_schedule(@center, @third_msi)
    MeetingScheduleManager.create_meeting_schedule(@center, @fourth_msi)

    MeetingScheduleManager.get_all_meeting_schedule_infos(@center).sort.should ==
      [@fourth_msi, @third_msi, @second_msi, @first_msi]

    expected_meeting_date_strs = ['2012-01-05', '2012-01-12', '2012-01-19', '2012-01-26',
      '2012-02-26', '2012-03-26',
      '2012-03-28', '2012-04-11', '2012-04-25', '2012-05-09',
      '2012-05-23', '2012-05-24', '2012-05-25', '2012-05-26', '2012-05-27']
    expected_meeting_dates = expected_meeting_date_strs.collect { |date_str| Date.parse(date_str) }

    MeetingScheduleManager.get_meetings_per_schedule(@center, Date.parse('2012-01-05'), Date.parse('2012-05-28')).should ==
      expected_meeting_dates
  end

end
