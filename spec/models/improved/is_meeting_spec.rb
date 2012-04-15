require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

class IsMeetingImpl
  include IsMeeting

  attr_reader :meeting_time_begins_hours, :meeting_time_begins_minutes

  def initialize(meeting_time_begins_hours, meeting_time_begins_minutes)
    if meeting_time_begins_hours
      raise ArgumentError, "the meeting time in hours: #{meeting_time_begins_hours} is not in the permissible range" unless Constants::Time::MEETING_HOURS_PERMISSIBLE_RANGE === meeting_time_begins_hours
    end
    if meeting_time_begins_minutes
      raise ArgumentError, "the meeting time in minutes: #{meeting_time_begins_minutes} is not in the permissible range" unless Constants::Time::MEETING_MINUTES_PERMISSIBLE_RANGE === meeting_time_begins_minutes
    end
    @meeting_time_begins_hours = meeting_time_begins_hours; @meeting_time_begins_minutes = meeting_time_begins_minutes
  end

end

describe IsMeetingImpl do

  before(:all) do
    @meeting_missing_hours = IsMeetingImpl.new(nil, 20)
    @meeting_missing_minutes = IsMeetingImpl.new(11, nil)
    @meeting_missing_both = IsMeetingImpl.new(nil, nil)
    @meeting_beginning_AM = IsMeetingImpl.new(10, 15)
    @meeting_beginning_PM = IsMeetingImpl.new(16, 30)

    @twelve_fmt = Constants::Time::TWELVE_HOUR_FORMAT
    @twenty_four_fmt = Constants::Time::TWENTY_FOUR_HOUR_FORMAT

    @test_times = [
      @meeting_missing_hours, @meeting_missing_minutes, @meeting_missing_both, @meeting_beginning_AM, @meeting_beginning_PM
    ]

    @sorted_times =
      [@meeting_missing_both, @meeting_missing_hours, @meeting_beginning_AM, @meeting_missing_minutes, @meeting_beginning_PM]

    @expected = {
      @meeting_missing_hours => { :minutes => 20, @twelve_fmt => "00:20 AM", @twenty_four_fmt => "00:20" },
      @meeting_missing_minutes => { :minutes => (11 * 60), @twelve_fmt => "11:00 AM", @twenty_four_fmt => "11:00" },
      @meeting_missing_both => { :minutes => 0,  @twelve_fmt => "00:00 AM", @twenty_four_fmt => "00:00" },
      @meeting_beginning_AM => { :minutes => ((10 * 60) + 15), @twelve_fmt => "10:15 AM", @twenty_four_fmt => "10:15" },
      @meeting_beginning_PM => { :minutes => ((16 * 60) + 30), @twelve_fmt => "04:30 PM", @twenty_four_fmt => "16:30" }
    }
  end
  
  it "should return the meeting time in minutes as expected" do
    @test_times.each do |meeting_time|
      meeting_time.meeting_begins_at_in_minutes.should == @expected[meeting_time][:minutes]
    end
  end

  it "should format the meeting time for 12 hour format" do
    @test_times.each do |meeting_time|
      meeting_time.meeting_begins_at(@twelve_fmt).should == @expected[meeting_time][@twelve_fmt]
    end
  end

  it "should format the meeting time for 24 hour format" do
    @test_times.each do |meeting_time|
      meeting_time.meeting_begins_at(@twenty_four_fmt).should == @expected[meeting_time][@twenty_four_fmt]
    end
  end

  it "should sort the meetings by absolute meeting time in minutes as expected" do
    @test_times.sort.should == @sorted_times
  end

  it "should format the meeting time for the default format as expected" do
    if Constants::Time::DEFAULT_MEETING_TIME_FORMAT == @twelve_fmt
      @test_times.each do |meeting_time|
        meeting_time.meeting_begins_at.should == @expected[meeting_time][@twelve_fmt]
      end
    end

    if Constants::Time::DEFAULT_MEETING_TIME_FORMAT == @twenty_four_fmt
      @test_times.each do |meeting_time|
        meeting_time.meeting_begins_at.should == @expected[meeting_time][@twenty_four_fmt]
      end
    end
  end

end
