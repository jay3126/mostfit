require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe UserFacade do

  before(:all) do
    @user_facade = UserFacade.instance

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

    @supervisor = Constants::User::SUPERVISOR
    @executive  = Constants::User::EXECUTIVE
    @support    = Constants::User::SUPPORT
    @read_only  = Constants::User::READ_ONLY

    @bmd = Factory.create(:designation, {:name => "BM", :role_class => @supervisor, :location_level => @branch_level})
    @rod = Factory.create(:designation, {:name => "RO", :role_class => @executive, :location_level => @branch_level})
    @aod = Factory.create(:designation, {:name => "AO", :role_class => @support, :location_level => @branch_level})
    @clerkd = Factory.create(:designation, {:name => "BM", :role_class => @supervisor, :location_level => @branch_level})
    @amd = Factory.create(:designation, {:name => "AM", :role_class => @supervisor, :location_level => @area_level})
    @rmd = Factory.create(:designation, {:name => "AM", :role_class => @supervisor, :location_level => @region_level})

    staff_member_attributes = Factory.attributes_for(:staff_member)

    @bm_user, @ro_user, @ao_user, @clerk_user, @am_user, @rm_user = 1.upto(6).collect {Factory(:user)}

    @bm = Factory.create(:staff_member, staff_member_attributes.merge({:user => @bm_user, :designation => @bmd}))
    @ro = Factory.create(:staff_member, staff_member_attributes.merge({:user => @ro_user, :designation => @rod}))
    @ao = Factory.create(:staff_member, staff_member_attributes.merge({:user => @ao_user, :designation => @aod}))
    @clerk = Factory.create(:staff_member, staff_member_attributes.merge({:user => @clerk_user, :designation => @clerkd}))
    @am = Factory.create(:staff_member, staff_member_attributes.merge({:user => @am_user, :designation => @amd}))
    @rm = Factory.create(:staff_member, staff_member_attributes.merge({:user => @rm_user, :designation => @rmd}))
  end

  it "should return the user for a given user ID as expected" do
    bm_user_id = @bm_user.id
    @user_facade.get_user(bm_user_id).should == @bm_user
  end

  it "should return the user for a given login as expected" do
    bm_user_login = @bm_user.login
    @user_facade.get_user_for_login(bm_user_login).should == @bm_user
  end

  it "should return the first user as expected" do
    first_user = User.first
    @user_facade.get_first_user.should == first_user
  end

end