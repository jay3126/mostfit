require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe Constants::Time do

  it "should correctly indicate the last day of the month" do
    Constants::Time.is_last_day_of_month?(Date.parse('2012-01-31')).should be_true
    Constants::Time.is_last_day_of_month?(Date.parse('2011-12-31')).should be_true    
    Constants::Time.is_last_day_of_month?(Date.parse('2012-02-29')).should be_true

    1.upto(30).each { |n|
      Constants::Time.is_last_day_of_month?(Date.parse("2012-01-#{n}")).should be_false
    }    
  end

  it "should correctly indicate the first day of month" do
    Constants::Time.is_first_day_of_month?(Date.parse('2012-01-01')).should be_true
    Constants::Time.is_first_day_of_month?(Date.parse('2011-12-01')).should be_true    
    Constants::Time.is_first_day_of_month?(Date.parse('2012-03-01')).should be_true

    2.upto(31).each { |n|
      Constants::Time.is_first_day_of_month?(Date.parse("2012-01-#{n}")).should be_false
    }    
  end

  it "should return the correct date for a desired weekday after a given day" do
    on_or_after_date = Date.parse('2012-04-23')
    Constants::Time.get_next_date_for_day(Constants::Time::SUNDAY, on_or_after_date).should == (on_or_after_date + 6)
    Constants::Time.get_next_date_for_day(Constants::Time::MONDAY, on_or_after_date).should == on_or_after_date
    Constants::Time.get_next_date_for_day(Constants::Time::TUESDAY, on_or_after_date).should == on_or_after_date + 1
    Constants::Time.get_next_date_for_day(Constants::Time::WEDNESDAY, on_or_after_date).should == on_or_after_date + 2
    Constants::Time.get_next_date_for_day(Constants::Time::THURSDAY, on_or_after_date).should == on_or_after_date + 3
    Constants::Time.get_next_date_for_day(Constants::Time::FRIDAY, on_or_after_date).should == on_or_after_date + 4
    Constants::Time.get_next_date_for_day(Constants::Time::SATURDAY, on_or_after_date).should == on_or_after_date + 5
  end

  it "should return the Sunday immediately preceding" do
    sunday = Date.parse('2012-04-22')
    on_date_mon = Date.parse('2012-04-23')
    on_date_tue = Date.parse('2012-04-24')
    on_date_web = Date.parse('2012-04-25')
    on_date_thu = Date.parse('2012-04-26')
    on_date_fri = Date.parse('2012-04-27')
    on_date_sat = Date.parse('2012-04-28')
    on_date_sun = Date.parse('2012-04-29')
    Constants::Time::get_beginning_sunday(sunday).should == sunday
    Constants::Time::get_beginning_sunday(on_date_mon).should == sunday
    Constants::Time::get_beginning_sunday(on_date_tue).should == sunday
    Constants::Time::get_beginning_sunday(on_date_web).should == sunday
    Constants::Time::get_beginning_sunday(on_date_thu).should == sunday
    Constants::Time::get_beginning_sunday(on_date_fri).should == sunday
    Constants::Time::get_beginning_sunday(on_date_sat).should == sunday
    Constants::Time::get_beginning_sunday(on_date_sun).should == on_date_sun
  end

  it "should return a list of the dates of the week commencing from the immediately preceding Sunday" do
    on_date = Date.parse('2012-04-23')
    on_date_sun = Date.parse('2012-04-22')
    on_date_mon = Date.parse('2012-04-23')
    on_date_tue = Date.parse('2012-04-24')
    on_date_wed = Date.parse('2012-04-25')
    on_date_thu = Date.parse('2012-04-26')
    on_date_fri = Date.parse('2012-04-27')
    on_date_sat = Date.parse('2012-04-28')
    
    week_dates = Constants::Time::get_current_week_dates(on_date)
    week_dates.should be_an_instance_of Array
    week_dates.each { |date|
      date.should be_an_instance_of Date
    }
    week_dates.size.should == 7
    
    week_dates[0].weekday.should == Constants::Time::SUNDAY
    week_dates[1].weekday.should == Constants::Time::MONDAY
    week_dates[2].weekday.should == Constants::Time::TUESDAY
    week_dates[3].weekday.should == Constants::Time::WEDNESDAY
    week_dates[4].weekday.should == Constants::Time::THURSDAY
    week_dates[5].weekday.should == Constants::Time::FRIDAY
    week_dates[6].weekday.should == Constants::Time::SATURDAY

    week_dates[0].should == on_date_sun
    week_dates[1].should == on_date_mon
    week_dates[2].should == on_date_tue
    week_dates[3].should == on_date_wed
    week_dates[4].should == on_date_thu
    week_dates[5].should == on_date_fri
    week_dates[6].should == on_date_sat

  end

  it "should get the next date for the weekly frequency as expected" do
    monday = Date.parse('2012-04-30')
    Constants::Time.get_next_date(monday, MarkerInterfaces::Recurrence::WEEKLY).should == (monday + 7)
  end

  it "should get the next date for the biweekly frequency as expected" do
    monday = Date.parse('2012-04-30')
    Constants::Time.get_next_date(monday, MarkerInterfaces::Recurrence::BIWEEKLY).should == (monday + 14)
  end

  it "should get the next date for monthly frequency as expected" do
    saturday = Date.parse('2012-04-28')
    Constants::Time.get_next_date(saturday, MarkerInterfaces::Recurrence::MONTHLY).should == Date.parse('2012-05-28')
  end
  
  it "should raise an error if requested for a date with an interval of one month when the date is beyond the permitted date limit" do
    monday = Date.parse('2012-04-30')
    lambda { Constants::Time.get_next_date(monday, MarkerInterfaces::Recurrence::MONTHLY) }.should raise_error
  end

  it "should get the date for the next month as expected using the date of the month" do
    thirtieth_jan = Date.parse('2012-01-30')
    lambda { Constants::Time.get_next_month_date(thirtieth_jan) }.should raise_error

    thirty_first_december = Date.parse('2011-12-31')
    Constants::Time.get_next_month_date(thirty_first_december).should == Date.parse('2012-01-31')
    
    fifteenth_april = Date.parse('2012-04-15')
    Constants::Time.get_next_month_date(fifteenth_april).should == Date.parse('2012-05-15')
  end

  it "should return the immediately earlier date as expected" do
    test_date_strings = %w[2012-01-03 2012-01-07 2012-01-11 2012-01-23
2012-05-31]
    test_dates = test_date_strings.collect {|str| Date.parse(str)}

    second = Date.parse('2012-01-02')
    Constants::Time.get_immediately_earlier_date(second,
                                                 *test_dates).should == nil

    fourth = Date.parse('2012-01-04')
    Constants::Time.get_immediately_earlier_date(fourth,
                                                 *test_dates).should == Date.parse('2012-01-03')

    seventh = Date.parse('2012-01-07')
    Constants::Time.get_immediately_earlier_date(seventh,
                                                 *test_dates).should == seventh

    much_later = Date.parse('2013-01-01')
    Constants::Time.get_immediately_earlier_date(much_later,
                                                 *test_dates) == test_dates.sort.last

  end

  it "should return the immediately next date as expected" do
    test_date_strings = %w[2012-01-03 2012-01-07 2012-01-11 2012-01-23
2012-05-31]
    test_dates = test_date_strings.collect {|str| Date.parse(str)}

    second = Date.parse('2012-01-02')
    Constants::Time.get_immediately_next_date(second, *test_dates).should ==
        Date.parse('2012-01-03')

    fourth = Date.parse('2012-01-04')
    Constants::Time.get_immediately_next_date(fourth, *test_dates).should ==
        Date.parse('2012-01-07')

    seventh = Date.parse('2012-01-07')
    Constants::Time.get_immediately_next_date(seventh, *test_dates).should ==
        seventh

    much_later = Date.parse('2013-01-01')
    Constants::Time.get_immediately_next_date(much_later, *test_dates) == nil

  end

  it "should order dates as expected" do
    today = Date.today
    day_before_yesterday = today - 2
    day_after_tomorrow   = today + 2

    Constants::Time.ordered_dates(today, day_before_yesterday).should == [day_before_yesterday, today]
    Constants::Time.ordered_dates(today, today).should == [today, today]
    Constants::Time.ordered_dates(day_before_yesterday, today).should == [day_before_yesterday, today]
    Constants::Time.ordered_dates(day_after_tomorrow, day_after_tomorrow).should == [day_after_tomorrow, day_after_tomorrow]
    Constants::Time.ordered_dates(day_after_tomorrow, today).should == [today, day_after_tomorrow]
  
  end

end
