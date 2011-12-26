require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe SurpriseCenterVisit do

  before(:all) do
    @date = Date.new(2010, 8, 14)
    @staff_member = StaffMember.new(:name => "Mrs. M.A. Nerger", :gender => :female)
    @staff_member.should be_valid
    @staff_member.save
    @branch = Branch.new(:name => "Kerela branch")
    @branch.manager = @staff_member
    @branch.code = "bra"
    @branch.save
    @branch.should be_valid
    @center = Center.new(:name => "Munnar hill center")
    @center.manager = @staff_member
    @center.branch = @branch
    @center.creation_date = Date.new(2010, 1, 1)
    @center.meeting_day = :monday
    @center.code = "center"
    @center.save
    @center.should be_valid
  end

  it "should have a center" do
    surprise_center_visit = SurpriseCenterVisit.new(:done_on => @date)
    surprise_center_visit.conducted_by = @staff_member
    surprise_center_visit.center = nil
    surprise_center_visit.should_not be_valid
    surprise_center_visit.center = @center
    surprise_center_visit.should be_valid
    surprise_center_visit.save.should be_true
  end

  it "should have a staff member" do
    surprise_center_visit = SurpriseCenterVisit.new(:done_on => @date)
    surprise_center_visit.center = @center  
    surprise_center_visit.conducted_by = nil
    surprise_center_visit.should_not be_valid
    surprise_center_visit.conducted_by = @staff_member
    surprise_center_visit.should be_valid
    surprise_center_visit.save.should be_true
  end

  it "should not be done on before its center has been created" do
    date = Date.new(1947,8,15)
    surprise_center_visit = SurpriseCenterVisit.new
    surprise_center_visit.center = @center  
    surprise_center_visit.conducted_by = @staff_member
    surprise_center_visit.done_on = date
    surprise_center_visit.should_not be_valid
    surprise_center_visit.done_on = @date
    surprise_center_visit.should be_valid
    surprise_center_visit.save.should be_true
  end

end
