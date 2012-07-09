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

  it "should aggregate locations by location level as expected" do    
    center, branch, area, region = (0.upto(3).to_a).zip(['center', 'branch', 'region', 'area']).collect {|el|
      {:level => el.first, :name => el.last}
    }

    @center_level = LocationLevel.create Factory.attributes_for(:location_level, center)
    @branch_level = LocationLevel.create Factory.attributes_for(:location_level, branch)
    @area_level   = LocationLevel.create Factory.attributes_for(:location_level, area)
    @region_level = LocationLevel.create Factory.attributes_for(:location_level, region)

    location_attributes = Factory.attributes_for(:biz_location)
    @branch_one = Factory.create(:biz_location, location_attributes.merge(:location_level => @branch_level))
    @branch_two = Factory.create(:biz_location, location_attributes.merge(:location_level => @branch_level))

    @center_one = Factory.create(:biz_location, location_attributes.merge(:location_level => @center_level))
    @center_two = Factory.create(:biz_location, location_attributes.merge(:location_level => @center_level))

    @region_one = Factory.create(:biz_location, location_attributes.merge(:location_level => @region_level))
    @region_two = Factory.create(:biz_location, location_attributes.merge(:location_level => @region_level))

    @area_one = Factory.create(:biz_location, location_attributes.merge(:location_level => @area_level))
    @area_two = Factory.create(:biz_location, location_attributes.merge(:location_level => @area_level))

    all_locations = [@branch_one, @center_one, @center_two, @region_one, @region_two]
    all_locations_map = {
      @center_level => [@center_one, @center_two],
      @branch_level => [@branch_one],
      @region_level => [@region_one, @region_two]
    }

    mapped_locations = BizLocation.map_by_level(*all_locations)

    location_level_keys = mapped_locations.keys
    location_level_keys.size.should == all_locations_map.keys.size
    location_level_keys.include?(@center_level).should be_true
    location_level_keys.include?(@branch_level).should be_true
    location_level_keys.include?(@region_level).should be_true

    mapped_locations[@center_level].size.should == all_locations_map[@center_level].size
    mapped_locations[@center_level].include?(@center_one).should be_true
    mapped_locations[@center_level].include?(@center_two).should be_true

    mapped_locations[@branch_level].size.should == all_locations_map[@branch_level].size
    mapped_locations[@branch_level].include?(@branch_one).should be_true
    mapped_locations[@branch_level].include?(@branch_two).should be_false

    mapped_locations[@region_level].size.should == all_locations_map[@region_level].size
    mapped_locations[@region_level].include?(@region_one).should be_true
    mapped_locations[@region_level].include?(@region_two).should be_true
  end


end
