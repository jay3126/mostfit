require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LoanApplication do

  before(:all) do
    @staff_member = Factory(:staff_member)
    @user = Factory(:user)
    @center = Factory(:center)
    @branch = Factory(:branch)
  end

  before(:each) do
    LoanApplication.all.destroy!
    @lap = LoanApplication.new
    @lap.created_on = Date.today
    @lap.created_by_user_id = @user.id
    @lap.created_by_staff_id = @staff_member.id
    @lap.at_branch_id = @branch.id
    @lap.at_center_id = @center.id
    @lap.amount = 4200
    @lap.client_name = 'HetalBen'
    @lap.client_dob  = Date.new(1962, 4, 1)
    @lap.client_guarantor_name = 'Hetalbhai'
    @lap.client_guarantor_relationship = 'Husband'
    @lap.client_reference1 = 'ration_card_no'
    @lap.client_reference1_type = 'Ration Card'
    @lap.client_reference2 = 'Voter ID String'
    @lap.client_reference2_type = 'Voter ID'
    @lap.client_address = 'Limbdi, Ahmedabad'
    @lap.client_state = 'gujarat'
    @lap.client_pincode = '364002'
    @lap.center_cycle_id = 1
    @lap.valid?.should be_true
    @lap.save.should be_true
  end

  it "should not have duplicate references within the same center cycle" do
    attributes = @lap.attributes
    attributes.delete(:id)
    lap = LoanApplication.new(attributes)
    lap.valid?.should be_false
    lap.save.should be_false
    lap.client_reference1 = "123459IJU"
    lap.client_reference2 = "MH4521890"
    lap.valid?.should be_true
    lap.save.should be_true
  end

  it "should have a new status when created" do
    @lap.get_status.should == Constants::Status::NEW_STATUS
  end

  it "should be pending verification when newly created" do
    @lap.is_pending_verification?.should == true
  end

  it "should be pending verification when only CPV1 is accepted" do
    ClientVerification.record_CPV1_approved(@lap.id, @staff_member.id, Date.today, @user.id)
    ClientVerification.get_CPV1_status(@lap.id).should == Constants::Verification::VERIFIED_ACCEPTED
    @lap.is_pending_verification?.should == true
  end

  it "should NOT be pending verification when CPV2 is accepted" do
    ClientVerification.record_CPV1_approved(@lap.id, @staff_member.id, Date.today, @user.id)
    ClientVerification.get_CPV1_status(@lap.id).should == Constants::Verification::VERIFIED_ACCEPTED
    ClientVerification.record_CPV2_approved(@lap.id, @staff_member.id, Date.today, @user.id)
    ClientVerification.get_CPV2_status(@lap.id).should == Constants::Verification::VERIFIED_ACCEPTED

    @lap.is_pending_verification?.should_not == true
  end 

  it "should NOT be pending verification when CPV2 is rejected" do
    ClientVerification.record_CPV1_approved(@lap.id, @staff_member.id, Date.today, @user.id)
    ClientVerification.get_CPV1_status(@lap.id).should == Constants::Verification::VERIFIED_ACCEPTED

    ClientVerification.record_CPV2_rejected(@lap.id, @staff_member.id, Date.today, @user.id)
    ClientVerification.get_CPV2_status(@lap.id).should == Constants::Verification::VERIFIED_REJECTED
    
    @lap.is_pending_verification?.should_not == true
  end 

  it "should NOT be pending verification when CPV1 is rejected" do
    ClientVerification.record_CPV1_rejected(@lap.id, @staff_member.id, Date.today, @user.id)
    ClientVerification.get_CPV1_status(@lap.id).should == Constants::Verification::VERIFIED_REJECTED

    @lap.is_pending_verification?.should_not == true
  end 
  
  it "should return a info object containing info about all CPVs related to this LoanApplication" do
    ClientVerification.record_CPV1_approved(@lap.id, @staff_member.id, Date.today, @user.id)
    ClientVerification.get_CPV1_status(@lap.id).should == Constants::Verification::VERIFIED_ACCEPTED
    ClientVerification.record_CPV2_approved(@lap.id, @staff_member.id, Date.today, @user.id)
    ClientVerification.get_CPV2_status(@lap.id).should == Constants::Verification::VERIFIED_ACCEPTED

    lapinfo = @lap.to_info()
    #get the ClientVerification objet
    cpv1 = ClientVerification.get_CPV1(@lap.id)
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
    cpv2 = ClientVerification.get_CPV2(@lap.id)
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
    ClientVerification.record_CPV1_approved(@lap.id, @staff_member.id, Date.today, @user.id)
    ClientVerification.get_CPV1_status(@lap.id).should == Constants::Verification::VERIFIED_ACCEPTED
    ClientVerification.record_CPV2_approved(@lap.id, @staff_member.id, Date.today, @user.id)
    ClientVerification.get_CPV2_status(@lap.id).should == Constants::Verification::VERIFIED_ACCEPTED
 end

end
