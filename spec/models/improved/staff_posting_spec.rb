require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe StaffPosting do

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
    @s3 = Factory.create(:staff_member, staff_attributes.merge(:creation_date => @staff_creation_date))
    @is_not_assigned = Factory.create(:staff_member, staff_attributes.merge(:creation_date => @staff_creation_date))

    @performed_by = Factory(:staff_member).id
    @recorded_by  = Factory(:user).id
    @recorded_by_id = @recorded_by.id

    @choice_facade = FacadeFactory.instance.get_instance(FacadeFactory::CHOICE_FACADE, @recorded_by)
  end

  it "should disallow assigning a staff member to two different locations on the same date" do
    effective_on = Date.parse('2012-04-01')
    StaffPosting.assign(@s1, @l1, effective_on, @performed_by, @recorded_by_id)
    lambda{ StaffPosting.assign(@s1, @l2, effective_on, @performed_by, @recorded_by_id) }.should raise_error
  end

  it "should assign staff members to a location as expected" do
    s1_date = Date.parse('2012-04-01')
    s2_date = s1_date + 3
    StaffPosting.assign(@s1, @l1, s1_date, @performed_by, @recorded_by_id)
    StaffPosting.assign(@s2, @l1, s2_date, @performed_by, @recorded_by_id)

    s1_date_staff = StaffPosting.get_staff_assigned(@l1.id, s1_date)
    s1_date_staff.length.should == 1
    s1_date_staff.first.staff_assigned.should == @s1

    s2_date_staff = (StaffPosting.get_staff_assigned(@l1.id, s2_date)).sort
    s2_date_staff.length.should == 2
    s2_date_staff.first.staff_assigned.should == @s2
    s2_date_staff.last.staff_assigned.should == @s1
  end
  
  it "should return the staff assigned to a location as per the effective date" do
    effective_on = Date.parse('2012-04-01')
    StaffPosting.get_staff_assigned(@l1.id, (effective_on)).should be_empty

    StaffPosting.assign(@s1, @l1, effective_on, @performed_by, @recorded_by_id)

    StaffPosting.get_staff_assigned(@l1.id, (effective_on - 1)).should be_empty

    StaffPosting.get_assigned_location(@s1.id, effective_on - 1).should be_nil
    StaffPosting.get_assigned_location(@s1.id, effective_on).staff_assigned.should == @s1
    StaffPosting.get_assigned_location(@s1.id, effective_on + 10).staff_assigned.should == @s1
  end

  it "should reflect the reassignment of staff members to different locations over time" do
    effective_on = Date.parse('2012-04-01')
    StaffPosting.assign(@s1, @l1, effective_on, @performed_by, @recorded_by_id)

    StaffPosting.get_staff_assigned(@l1.id, effective_on).first.staff_assigned.should == @s1

    StaffPosting.assign(@s1, @l2, effective_on + 3, @performed_by, @recorded_by_id)
    StaffPosting.assign(@s2, @l1, effective_on + 3, @performed_by, @recorded_by_id)

    StaffPosting.get_staff_assigned(@l1.id, (effective_on + 3)).length.should == 1
    StaffPosting.get_staff_assigned(@l1.id, (effective_on + 3)).first.staff_assigned.should == @s2
    StaffPosting.get_staff_assigned(@l2.id, (effective_on + 3)).first.staff_assigned.should == @s1
  end

  it "should indicate that a location does not have any staff posted when none are assigned" do
    StaffPosting.get_staff_assigned(@l1.id, Date.today).should be_empty
  end

  it "should indicate that staff is not assigned to any location until assigned" do
    StaffPosting.get_assigned_location(@s1.id, Date.today).should be_nil
  end

  it "should disallow assigning a staff as manager before the date that either the staff member or the location is created" do
    lambda{ StaffPosting.assign(@s1, @l1, (@staff_creation_date - 1), @performed_by, @recorded_by_id) }.should raise_error
    lambda{ StaffPosting.assign(@s1, @l1, (@location_creation_date - 1), @performed_by, @recorded_by_id) }.should raise_error
  end

  it "should disallow assigning a staff as manager when the staff is inactive" do
    @s1.update(:active => false)
    @s1.active.should be_false
    lambda{ StaffPosting.assign(@s1, @l1, Date.today, @performed_by, @recorded_by_id) }.should raise_error
  end

end