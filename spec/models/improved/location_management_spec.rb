require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LocationManagement do

  before(:each) do
    @location_creation_date = Date.parse('2012-01-01')
    location_attributes = Factory.attributes_for(:biz_location)
    @l1 = Factory.create(:biz_location, location_attributes.merge(:creation_date => @location_creation_date))
    @l2 = Factory.create(:biz_location, location_attributes.merge(:creation_date => @location_creation_date))
    @l3 = Factory.create(:biz_location, location_attributes.merge(:creation_date => @location_creation_date))
    @l4 = Factory.create(:biz_location, location_attributes.merge(:creation_date => @location_creation_date))
    @all_locations = [@l1, @l2, @l3, @l4]

    @staff_creation_date = Date.parse('2012-02-01')
    staff_attributes = Factory.attributes_for(:staff_member)
    @s1 = Factory.create(:staff_member, staff_attributes.merge(:creation_date => @staff_creation_date))
    @s2 = Factory.create(:staff_member, staff_attributes.merge(:creation_date => @staff_creation_date))
    @does_not_manage = Factory.create(:staff_member, staff_attributes.merge(:creation_date => @staff_creation_date))

    @performed_by = Factory(:staff_member).id
    @recorded_by  = Factory(:user).id
  end

  it "should return the staff managing a location as per the effective date" do
    effective_on = Date.parse('2012-04-01')
    LocationManagement.assign_manager_to_location(@s1, @l1, effective_on, @performed_by, @recorded_by)

    LocationManagement.staff_managing_location(@l1.id, effective_on - 1).should be_nil

    manager_on_date = LocationManagement.staff_managing_location(@l1.id, effective_on)
    manager_on_date.manager_staff_member.should == @s1

    manager_after_date = LocationManagement.staff_managing_location(@l1.id, effective_on + 1)
    manager_after_date.manager_staff_member.should == @s1

    LocationManagement.locations_managed_by_staff(@s1.id, effective_on - 1).should == []
    instances = LocationManagement.locations_managed_by_staff(@s1.id, effective_on)
    instances.first.managed_location.should == @l1
    instances.first.manager_staff_member.should == @s1

    later_instances = LocationManagement.locations_managed_by_staff(@s1.id, effective_on + 10)
    later_instances.sort.should == instances.sort

    much_later = effective_on + 23
    LocationManagement.assign_manager_to_location(@s1, @l2, much_later, @performed_by, @recorded_by)
    much_later_instances = LocationManagement.locations_managed_by_staff(@s1.id, much_later)
    locations_managed = much_later_instances.sort.collect {|instance| instance.managed_location}
    locations_managed.should == [@l2, @l1]
  end

  it "should return the series of staff managing a location as per the effective date when managers are assigned serially" do
    first_manage_date = Date.parse('2012-04-01')
    LocationManagement.assign_manager_to_location(@s1, @l1, first_manage_date, @performed_by, @recorded_by)
    
    second_manage_date = Date.parse('2012-04-02')
    LocationManagement.assign_manager_to_location(@s2, @l1, second_manage_date, @performed_by, @recorded_by)

    earlier_manager_instance = LocationManagement.staff_managing_location(@l1.id, first_manage_date - 1)
    earlier_manager_instance.should be_nil
    
    first_manager_instance = LocationManagement.staff_managing_location(@l1.id, first_manage_date)
    first_manager_instance.manager_staff_member.should == @s1

    second_manager_instance = LocationManagement.staff_managing_location(@l1.id, second_manage_date)
    second_manager_instance.manager_staff_member.should == @s2

    later_manager_instance = LocationManagement.staff_managing_location(@l1.id, second_manage_date + 1)
    later_manager_instance.should == second_manager_instance
  end


  it "should indicate that a location does not have a manager when none is assigned" do
    @all_locations.each { |location|
      LocationManagement.staff_managing_location(location.id, Date.today).should be_nil
    }
  end

  it "should disallow assigning a staff as manager before the date that either the staff member or the location is created" do
    lambda {LocationManagement.assign_manager_to_location(@s1, @l1, @staff_creation_date - 1, @performed_by, @recorded_by)}.should raise_error
    lambda {LocationManagement.assign_manager_to_location(@s1, @l1, @location_creation_date - 1, @performed_by, @recorded_by)}.should raise_error
  end

  it "should disallow assigning a staff as manager when the staff is inactive" do
    @s1.update(:active => false)
    @s1.active.should be_false
    lambda {LocationManagement.assign_manager_to_location(@s1, @l1, Date.today, @performed_by, @recorded_by)}.should raise_error
  end

end
