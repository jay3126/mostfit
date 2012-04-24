require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe Constants::Time do

  before(:all) do
  end

  it "should return the correct date for a desired weekday after a given day" do
    on_or_after_date = Date.parse('2012-04-23')
    Constants::Time.get_next_date_for_day(:sunday, on_or_after_date).should == (on_or_after_date + 6)
    Constants::Time.get_next_date_for_day(:monday, on_or_after_date).should == on_or_after_date
    Constants::Time.get_next_date_for_day(:tuesday, on_or_after_date).should == on_or_after_date + 1
    Constants::Time.get_next_date_for_day(:wednesday, on_or_after_date).should == on_or_after_date + 2
    Constants::Time.get_next_date_for_day(:thursday, on_or_after_date).should == on_or_after_date + 3
    Constants::Time.get_next_date_for_day(:friday, on_or_after_date).should == on_or_after_date + 4
    Constants::Time.get_next_date_for_day(:saturday, on_or_after_date).should == on_or_after_date + 5
  end

  it "should be return start date of week(sunday)" do
    on_date_mon = Date.parse('2012-04-23')
    on_date_tue = Date.parse('2012-04-24')
    on_date_web = Date.parse('2012-04-25')
    on_date_thu = Date.parse('2012-04-26')
    on_date_fri = Date.parse('2012-04-27')
    on_date_sat = Date.parse('2012-04-28')
    on_date_sun = Date.parse('2012-04-29')
    Constants::Time::get_beginning_sunday(on_date_mon).weekday.should == :sunday
    Constants::Time::get_beginning_sunday(on_date_tue).weekday.should == :sunday
    Constants::Time::get_beginning_sunday(on_date_web).weekday.should == :sunday
    Constants::Time::get_beginning_sunday(on_date_thu).weekday.should == :sunday
    Constants::Time::get_beginning_sunday(on_date_fri).weekday.should == :sunday
    Constants::Time::get_beginning_sunday(on_date_sat).weekday.should == :sunday
    Constants::Time::get_beginning_sunday(on_date_sun).weekday.should == :sunday
  end

  it "should be return Array of Dates of week" do
    on_date = Date.parse('2012-04-23')
    week_days = Constants::Time::get_current_week_dates(on_date)
    week_days.should be_an_instance_of Array
    week_days.first.should be_an_instance_of Date
    week_days.first.should be_an_instance_of Date
    week_days.last.should be_an_instance_of Date
    week_days.size.should == 7
    week_days[0].weekday.should == :sunday
    week_days[1].weekday.should == :monday
    week_days[2].weekday.should == :tuesday
    week_days[3].weekday.should == :wednesday
    week_days[4].weekday.should == :thursday
    week_days[5].weekday.should == :friday
    week_days[6].weekday.should == :saturday
  end
end
