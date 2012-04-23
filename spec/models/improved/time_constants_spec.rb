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

end
