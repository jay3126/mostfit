require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe Constants::Time do

  before(:all) do
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

  it "should be return start date of week(sunday)" do
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

  it "should be return Array of Dates of week" do
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
end
