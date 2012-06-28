require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LocationLink do

  before(:all) do
    @center_level = LocationLevel.create(:level => 0, :name => "Center")
    @branch_level = LocationLevel.create(:level => 1, :name => "Branch")
    @area_level = LocationLevel.create(:level => 2, :name => "Area")
  end

  before(:each) do
    @area_one = BizLocation.create(:name => Factory.next(:province), :location_level => @area_level)
    
    @branch_one = BizLocation.create(:name => Factory.next(:province), :location_level => @branch_level)
    @branch_two = BizLocation.create(:name => Factory.next(:province), :location_level => @branch_level)

    @center_one = BizLocation.create(:name => Factory.next(:province), :location_level => @center_level)
    @center_two = BizLocation.create(:name => Factory.next(:province), :location_level => @center_level)
    @center_three = BizLocation.create(:name => Factory.next(:province), :location_level => @center_level)
    @center_four = BizLocation.create(:name => Factory.next(:province), :location_level => @center_level)
    @center_five = BizLocation.create(:name => Factory.next(:province), :location_level => @center_level)
  end

  it "should disallow linking locations when the location levels are not related correctly" do
    lambda {LocationLink.assign(@center_one, @center_two)}.should raise_error
    lambda {LocationLink.assign(@branch_one, @branch_two)}.should raise_error

    lambda {LocationLink.assign(@center_one, @center_one)}.should raise_error

    lambda {LocationLink.assign(@center_one, @area_one)}.should raise_error

    lambda {LocationLink.assign(@branch_one, @center_two)}.should raise_error
  end

  it "should disallow different location links for a child location on the same date" do
    LocationLink.assign(@center_one, @branch_one)
    lambda {LocationLink.assign(@center_one, @branch_one)}.should raise_error
    lambda {LocationLink.assign(@center_one, @branch_two)}.should raise_error
  end

  it "should only allow zero or one parent location for a location on a specified date"

  it "should disallow linking locations before either the parent or the child location are created" do
    parent_created_on = @branch_one.created_on
    child_created_on = @center_one.created_on

    lambda {LocationLink.assign(@center_one, @branch_one, (parent_created_on - 1))}.should raise_error
    lambda {LocationLink.assign(@center_one, @branch_one, (child_created_on - 1))}.should raise_error
  end

  it "should assign and return a child location as expected" do
    LocationLink.assign(@center_one, @branch_one)

    LocationLink.get_children(@branch_one).include?(@center_one).should == true
  end

  it "should return a parent location as expected" do
    LocationLink.assign(@center_two, @branch_two)
    
    LocationLink.get_parent(@center_two).should be_an_instance_of BizLocation
    LocationLink.get_parent(@center_two).should == @branch_two
  end

  it "should return the parent location for a location on the specified date" do
   
    date_1 = Date.today + 1
    date_2 = Date.today + 3

    LocationLink.assign(@center_one, @branch_one, date_1)
    LocationLink.assign(@center_two, @branch_two, date_2)

    LocationLink.get_parent(@center_one, date_1).should be_an_instance_of BizLocation
    LocationLink.get_parent(@center_one, date_1).should == @branch_one

    LocationLink.get_parent(@center_two, date_2).should be_an_instance_of BizLocation
    LocationLink.get_parent(@center_two, date_2).should == @branch_two

    LocationLink.assign(@center_one, @branch_two, date_2)
    LocationLink.assign(@center_two, @branch_one, date_1)

    LocationLink.get_parent(@center_one, date_2).should be_an_instance_of BizLocation
    LocationLink.get_parent(@center_one, date_2).should == @branch_two

    LocationLink.get_parent(@center_two, date_1).should be_an_instance_of BizLocation
    LocationLink.get_parent(@center_two, date_1).should == @branch_one
  end

  it "should return nil for the parent location for a specified date when there is no such link for the location" do
    date = Date.today + 1
    LocationLink.assign(@center_three, @branch_two, date)

    LocationLink.get_parent(@center_three, Date.today).should be_an_instance_of NilClass
    LocationLink.get_parent(@center_three, Date.today).should == nil
  end

  it "should return the child locations for a location on the specified date" do
    
    date_1 = Date.today + 1
    date_2 = Date.today + 3


    LocationLink.assign(@center_three, @branch_one, date_1)
    LocationLink.assign(@center_four, @branch_two, date_2)

    LocationLink.get_children(@branch_one, date_1).should be_an_instance_of Array
    LocationLink.get_children(@branch_one, date_1).include?(@center_three).should == true

    LocationLink.get_children(@branch_two, date_2).should be_an_instance_of Array
    LocationLink.get_children(@branch_two, date_2).include?(@center_four).should == true

    LocationLink.assign(@center_three, @branch_two, date_2)
    LocationLink.assign(@center_four, @branch_one, date_1)

    LocationLink.get_children(@branch_one, date_1).should be_an_instance_of Array
    LocationLink.get_children(@branch_one, date_1).include?(@center_four).should == true

    LocationLink.get_children(@branch_two, date_2).should be_an_instance_of Array
    LocationLink.get_children(@branch_two, date_2).include?(@center_three).should == true

  end

  it "should return an empty list for children when a location does not have child locations on a specified date" do
    date = Date.today + 5
    LocationLink.assign(@center_four, @branch_one, date)

    LocationLink.get_children(@branch_one, Date.today).should be_an_instance_of Array
    LocationLink.get_children(@branch_one, Date.today).blank?.should == true
  end

end