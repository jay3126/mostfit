require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe BizLocation do

  it "should not be possible to create a BizLocation before a location level exists" do
    location_level = Factory(:location_level)
    level_was_created_on = location_level.created_on
    level_number = location_level.level

    lambda {BizLocation.create_new_location("new location", (level_was_created_on - 1), level_number)}.should raise_error
    new_location = BizLocation.create_new_location("new location", level_was_created_on, level_number)
    new_location.should_not be_nil
    new_location.created_on.should == level_was_created_on
    new_location.name = "new location"

    another_location = BizLocation.create_new_location("another location", (level_was_created_on + 1), level_number)
    another_location.should_not be_nil
    another_location.created_on.should == (level_was_created_on + 1)
  end


end
