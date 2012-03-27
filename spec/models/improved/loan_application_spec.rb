require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LoanApplication do

  before(:each) do
    @lap = LoanApplication.new
    @time_datum = Time.now
    @created_on = Date.today
    @created_by_user_id = 1
    @created_by_staff_id = 2
    @at_branch_id = 1
    @at_center_id = 2
    @created_at = Time.now
    @amount = 4200.00
  end

  it "should have a new status when created" do
    @lap.get_status.should == Constants::Status::NEW_STATUS
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
    lap.created_on = @created_on
    lap.save

    ClientVerification.record_CPV1_approved(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)
    ClientVerification.get_CPV1_status(lap.id).should == Constants::Verification::VERIFIED_ACCEPTED
    lap.is_pending_verification?.should == true
  end

  it "should NOT be pending verification when CPV2 is accepted" do
    lap = LoanApplication.new()
    lap.id = ((Time.now - @time_datum) * 1000).to_i
    lap.at_branch_id = @at_branch_id
    lap.at_center_id = @at_center_id
    lap.created_by_staff_id = @created_by_staff_id
    lap.created_by_user_id = @created_by_user_id
    lap.created_on = @created_on
    lap.amount = @amount
    lap.save

    ClientVerification.record_CPV1_approved(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)
    ClientVerification.get_CPV1_status(lap.id).should == Constants::Verification::VERIFIED_ACCEPTED
    ClientVerification.record_CPV2_approved(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)
    ClientVerification.get_CPV2_status(lap.id).should == Constants::Verification::VERIFIED_ACCEPTED

    lap.is_pending_verification?.should_not == true
  end 

  it "should NOT be pending verification when CPV2 is rejected" do
    lap = LoanApplication.new()
    lap.id = ((Time.now - @time_datum) * 1000).to_i
    lap.at_branch_id = @at_branch_id
    lap.at_center_id = @at_center_id
    lap.created_by_staff_id = @created_by_staff_id
    lap.created_by_user_id = @created_by_user_id
    lap.created_on = @created_on
    lap.created_at = @created_at
    lap.amount = @amount
    lap.save
    ClientVerification.record_CPV1_approved(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)
    ClientVerification.get_CPV1_status(lap.id).should == Constants::Verification::VERIFIED_ACCEPTED

    ClientVerification.record_CPV2_rejected(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)
    ClientVerification.get_CPV2_status(lap.id).should == Constants::Verification::VERIFIED_REJECTED
    
    lap.is_pending_verification?.should_not == true
  end 

  it "should NOT be pending verification when CPV1 is rejected" do
    lap = LoanApplication.new()
    lap.id = ((Time.now - @time_datum) * 1000).to_i
    lap.at_branch_id = @at_branch_id
    lap.at_center_id = @at_center_id
    lap.created_by_staff_id = @created_by_staff_id
    lap.created_by_user_id = @created_by_user_id
    lap.created_on = @created_on
    lap.amount = @amount
    lap.save

    ClientVerification.record_CPV1_rejected(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)
    ClientVerification.get_CPV1_status(lap.id).should == Constants::Verification::VERIFIED_REJECTED

    lap.is_pending_verification?.should_not == true
  end 
  
  it "should return a info object containing info about all CPVs related to this LoanApplication" do
    lap = LoanApplication.new()
    lap.id = ((Time.now - @time_datum) * 1000).to_i
    lap.at_branch_id = @at_branch_id
    lap.at_center_id = @at_center_id
    lap.created_by_staff_id = @created_by_staff_id
    lap.created_by_user_id = @created_by_user_id
    lap.created_on = @created_on
    lap.amount = @amount
    lap.save
 
    ClientVerification.record_CPV1_approved(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)
    ClientVerification.get_CPV1_status(lap.id).should == Constants::Verification::VERIFIED_ACCEPTED
    ClientVerification.record_CPV2_approved(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)
    ClientVerification.get_CPV2_status(lap.id).should == Constants::Verification::VERIFIED_ACCEPTED

    lapinfo = lap.to_info()
    #get the ClientVerification objet
    cpv1 = ClientVerification.get_CPV1(lap.id)
    cpv1.should_not be_nil

    #compare them
    lapinfo.cpv1.loan_application_id.should == cpv1.loan_application_id
    lapinfo.cpv1.verification_type.should == cpv1.verification_type
    lapinfo.cpv1.verification_status.should == cpv1.verification_status
    lapinfo.cpv1.verified_by_staff_id.should == cpv1.verified_by_staff_id
    lapinfo.cpv1.verified_on_date.should == cpv1.verified_on_date
    lapinfo.cpv1.created_by_user_id.should == cpv1.created_by_user_id
    lapinfo.cpv1.created_at.should == cpv1.created_at
   
    #get the ClientVerification objet
    cpv2 = ClientVerification.get_CPV2(lap.id)
    cpv2.should_not be_nil

    #compare them
    lapinfo.cpv2.loan_application_id.should == cpv2.loan_application_id
    lapinfo.cpv2.verification_type.should == cpv2.verification_type
    lapinfo.cpv2.verification_status.should == cpv2.verification_status
    lapinfo.cpv2.verified_by_staff_id.should == cpv2.verified_by_staff_id
    lapinfo.cpv2.verified_on_date.should == cpv2.verified_on_date
    lapinfo.cpv2.created_by_user_id.should == cpv2.created_by_user_id
    lapinfo.cpv2.created_at.should == cpv2.created_at
  end

  it "should return the most recently recorded first when comparing " do
  
    lap = LoanApplication.new()
    lap.id = ((Time.now - @time_datum) * 1000).to_i
    lap.at_branch_id = @at_branch_id
    lap.at_center_id = @at_center_id
    lap.created_by_staff_id = @created_by_staff_id
    lap.created_by_user_id = @created_by_user_id
    lap.created_on = @created_on
    lap.amount = @amount
    lap.save
 
    ClientVerification.record_CPV1_approved(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)
    ClientVerification.get_CPV1_status(lap.id).should == Constants::Verification::VERIFIED_ACCEPTED
    ClientVerification.record_CPV2_approved(lap.id, @created_by_staff_id, Date.today, @created_by_user_id)
    ClientVerification.get_CPV2_status(lap.id).should == Constants::Verification::VERIFIED_ACCEPTED

 end
end
