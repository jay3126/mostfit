require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LoanApplication do

  before(:each) do
    @lap = LoanApplication.new
    @time_datum = Time.now
    @created_at = Date.today
    @created_by_user_id = 1
    @created_by_staff_id = 2
    @at_branch_id = 1
    @at_center_id = 2
    @amount = 4200.00
  end

  it "should have a new status when created" do
    @lap.get_status.should == Constants::Status::NEW_STATUS
  end

  it "should not be approved when created" do
    @lap.is_approved?.should == false
  end

  it "should be pending verification when newly created" do
    @lap.is_pending_verification?.should == true
  end

  it "should be pending verification when only CPV1 is accepted" do
    lap = LoanApplication.new()
    lap.id = ((Time.now - @time_datum) * 1000).to_i
    lap.at_branch_id = @at_branch_id
    lap.at_center_id = @at_center_id
    lap.created_by_staff_id = @created_by_staff_id
    lap.created_by_user_id = @created_by_user_id
    lap.amount = @amount
    lap.save

    ClientVerification.record_CPV1_approved(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)
    lap.is_pending_verification?.should == true
  end

  it "should NOT be pending verification when CPV2 is accepted" do
    lap = LoanApplication.new()
    lap.id = ((Time.now - @time_datum) * 1000).to_i
    lap.at_branch_id = @at_branch_id
    lap.at_center_id = @at_center_id
    lap.created_by_staff_id = @created_by_staff_id
    lap.created_by_user_id = @created_by_user_id
    lap.amount = @amount
    lap.save

    ClientVerification.record_CPV1_approved(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)
    ClientVerification.record_CPV2_approved(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)

    lap.is_pending_verification?.should_not == true
  end 

  it "should NOT be pending verification when CPV2 is rejected" do
    lap = LoanApplication.new()
    lap.id = ((Time.now - @time_datum) * 1000).to_i
    lap.at_branch_id = @at_branch_id
    lap.at_center_id = @at_center_id
    lap.created_by_staff_id = @created_by_staff_id
    lap.created_by_user_id = @created_by_user_id
    lap.amount = @amount
    lap.save

    ClientVerification.record_CPV1_approved(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)
    ClientVerification.record_CPV2_rejected(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)

    lap.is_pending_verification?.should_not == true
  end 


  it "should NOT be pending verification when CPV1 is rejected" do
    lap = LoanApplication.new()
    lap.id = ((Time.now - @time_datum) * 1000).to_i
    lap.at_branch_id = @at_branch_id
    lap.at_center_id = @at_center_id
    lap.created_by_staff_id = @created_by_staff_id
    lap.created_by_user_id = @created_by_user_id
    lap.amount = @amount
    lap.save

    ClientVerification.record_CPV1_rejected(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)

    lap.is_pending_verification?.should_not == true
  end 

end
