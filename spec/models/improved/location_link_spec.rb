require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LocationLink do

  it "should disallow linking locations that are at the same location level"

  it "should assign a location to another on the specified date"

  it "should only allow zero or one parent location for a location on a specified date"

  it "should return a child location as expected" do
    parent_biz_location = Factory(:biz_location)
    child_biz_location = Factory(:biz_location)
    LocationLink.assign(child_biz_location, parent_biz_location)

    LocationLink.get_children(parent_biz_location).should be_an_instance_of Array
    LocationLink.get_children(parent_biz_location).include?(child_biz_location).should == true

  end

  it "should return a parent location as expected" do
    parent_biz_location = Factory(:biz_location)
    child_biz_location = Factory(:biz_location)
    LocationLink.assign(child_biz_location, parent_biz_location)
    
    LocationLink.get_parent(child_biz_location).should be_an_instance_of BizLocation
    LocationLink.get_parent(child_biz_location).should == parent_biz_location
  end

  it "should return the parent location for a location on the specified date" do
    parent_biz_location_1 = Factory(:biz_location)
    child_biz_location_1 = Factory(:biz_location)
    parent_biz_location_2 = Factory(:biz_location)
    child_biz_location_2 = Factory(:biz_location)

    date_1 = Date.today + 1
    date_2 = Date.today + 3

    LocationLink.assign(child_biz_location_1, parent_biz_location_1, date_1)
    LocationLink.assign(child_biz_location_2, parent_biz_location_2, date_2)

    LocationLink.get_parent(child_biz_location_1, date_1).should be_an_instance_of BizLocation
    LocationLink.get_parent(child_biz_location_1, date_1).should == parent_biz_location_1

    LocationLink.get_parent(child_biz_location_2, date_2).should be_an_instance_of BizLocation
    LocationLink.get_parent(child_biz_location_2, date_2).should == parent_biz_location_2

    LocationLink.assign(child_biz_location_1, parent_biz_location_2, date_2)
    LocationLink.assign(child_biz_location_2, parent_biz_location_1, date_1)

    LocationLink.get_parent(child_biz_location_1, date_2).should be_an_instance_of BizLocation
    LocationLink.get_parent(child_biz_location_1, date_2).should == parent_biz_location_2

    LocationLink.get_parent(child_biz_location_2, date_1).should be_an_instance_of BizLocation
    LocationLink.get_parent(child_biz_location_2, date_1).should == parent_biz_location_1
  end

  it "should return nil for the parent location for a specified date when there is no such link for the location" do
    parent_biz_location = Factory(:biz_location)
    child_biz_location = Factory(:biz_location)
    date = Date.today + 1
    LocationLink.assign(child_biz_location, parent_biz_location, date)

    LocationLink.get_parent(child_biz_location, Date.today).should be_an_instance_of NilClass
    LocationLink.get_parent(child_biz_location, Date.today).should == nil
  end

  it "should return the child locations for a location on the specified date" do
    parent_biz_location_1 = Factory(:biz_location)
    child_biz_location_1 = Factory(:biz_location)
    parent_biz_location_2 = Factory(:biz_location)
    child_biz_location_2 = Factory(:biz_location)

    date_1 = Date.today + 1
    date_2 = Date.today + 3

    LocationLink.assign(child_biz_location_1, parent_biz_location_1, date_1)
    LocationLink.assign(child_biz_location_2, parent_biz_location_2, date_2)

    LocationLink.get_children(parent_biz_location_1, date_1).should be_an_instance_of Array
    LocationLink.get_children(parent_biz_location_1, date_1).include?(child_biz_location_1).should == true

    LocationLink.get_children(parent_biz_location_2, date_2).should be_an_instance_of Array
    LocationLink.get_children(parent_biz_location_2, date_2).include?(child_biz_location_2).should == true

    LocationLink.assign(child_biz_location_1, parent_biz_location_2, date_2)
    LocationLink.assign(child_biz_location_2, parent_biz_location_1, date_1)

    LocationLink.get_children(parent_biz_location_1, date_1).should be_an_instance_of Array
    LocationLink.get_children(parent_biz_location_1, date_1).include?(child_biz_location_2).should == true

    LocationLink.get_children(parent_biz_location_2, date_2).should be_an_instance_of Array
    LocationLink.get_children(parent_biz_location_2, date_2).include?(child_biz_location_1).should == true

  end

  it "should return an empty list for children when a location does not have child locations on a specified date" do
    parent_biz_location = Factory(:biz_location)
    child_biz_location = Factory(:biz_location)
    date = Date.today + 5
    LocationLink.assign(child_biz_location, parent_biz_location, date)

    LocationLink.get_children(parent_biz_location, Date.today).should be_an_instance_of Array
    LocationLink.get_children(parent_biz_location, Date.today).blank?.should == true
  end

end