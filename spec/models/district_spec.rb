require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe District do

  before(:all) do
    @manager = StaffMember.create(:name => "Region manager")
    @region  = Region.create(:name => "test region2", :manager => @manager)
    @region.should be_valid
    @area = Area.create(:name => "test area", :region => @region, :manager => @manager)
    @district = District.create(:name => "test district", :area => @area, :manager => @manager)
    @district.should be_valid
  end

  it "should have a name" do
    @district.name = nil
    @district.should_not be_valid
  end

  it "should have some branches" do
    @manager = StaffMember.new(:name => "Mrs. M.A. Nerger")
    @manager.save
    @manager.should be_valid
    @district.name =  "Foo"

    Branch.all.destroy!
    @branch = Branch.new(:name => "Kerela branch")
    @branch.manager = @manager
    @branch.code = "branch"
    @branch.district = @district
    @branch.save
    @branch.errors.each {|e| p e}
    @branch.should be_valid

    @branch.should be_valid
    @district.branches.should == [@branch]
  end
end

