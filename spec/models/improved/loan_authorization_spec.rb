require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LoanAuthorization do

  before(:all) do
    @staff_member     = Factory(:staff_member)
    @performed_on     = Date.new(2011, 12, 11)
    @user             = Factory(:user)
    @loan_application = Factory(:loan_application)
  end

  before(:each) do
    LoanApplication.all.destroy!
    LoanAuthorization.all.destroy!
    @loan_application = Factory(:loan_application)
  end
  
  it "should be unique for each loan application" do
    status = Constants::Status::APPLICATION_OVERRIDE_APPROVED
    override_reason = Constants::Status::REASON_1
    loan_authorization1 = LoanAuthorization.record_authorization(@loan_application.id, status, @staff_member.id, @performed_on, @user.id, override_reason)
    loan_authorization1.should be_valid
    loan_authorization1.saved?.should be_true
    loan_authorization2 = LoanAuthorization.record_authorization(@loan_application.id, status, @staff_member.id, @performed_on, @user.id, override_reason)
    loan_authorization2.should_not be_valid
    loan_authorization2.saved?.should be_false
  end

  it "should find the authorization for a loan application when an authorization is recorded" do
    status = Constants::Status::APPLICATION_APPROVED
    LoanAuthorization.record_authorization(@loan_application.id, status, @staff_member.id, @performed_on, @user.id)
    LoanAuthorization.get_authorization(@loan_application.id).should_not be_nil
  end
  
  it "should return nil for a loan application when no authorization has been recorded" do
    LoanAuthorization.get_authorization(@loan_application.id).should be_nil
  end

  it "should be valid with an override reason when the authorization is an override" do
    loan_application_id = 1
    status = Constants::Status::APPLICATION_OVERRIDE_APPROVED
    override_reason = Constants::Status::REASON_1
    LoanAuthorization.record_authorization(loan_application_id, status, @staff_member.id, @performed_on, @user.id, override_reason)
  end
  
  it "should not be valid without an override reason when the authorization is an override" do
    loan_application_id = 2
    status = Constants::Status::APPLICATION_OVERRIDE_REJECTED
    override_reason = nil
    loan_auth = LoanAuthorization.record_authorization(loan_application_id, status, @staff_member.id, @performed_on, @user.id, override_reason)
    loan_auth.should_not be_valid
  end
  
  it "should return the correct status as authorized approved when it is authorized approved with or without an override" do
    by_staff_id = 3
    performed_on = Date.today
    created_by = 5
  
    # With authorized override
    with_override_loan_application_id = 5
    with_override_status = Constants::Status::APPLICATION_OVERRIDE_APPROVED
    with_override_reason = Constants::Status::REASON_1
    LoanAuthorization.record_authorization(with_override_loan_application_id, with_override_status, by_staff_id, performed_on, created_by, with_override_reason)
    LoanAuthorization.get_authorization(with_override_loan_application_id).should_not be_nil
    LoanAuthorization.is_approved?(with_override_loan_application_id).should == true

    # Without authorize override
    without_override_loan_application_id = 6
    without_override_status = Constants::Status::APPLICATION_APPROVED
    without_override_reason = Constants::Status::REASON_2
    LoanAuthorization.record_authorization(without_override_loan_application_id, without_override_status, by_staff_id, performed_on, created_by, without_override_reason)
    LoanAuthorization.get_authorization(without_override_loan_application_id).should_not be_nil
    LoanAuthorization.is_approved?(without_override_loan_application_id).should == true
  end

  it "should return the correct status as authorized rejected when it is authorized rejected with or without an override" do
    by_staff_id = 3
    performed_on = Date.today
    created_by = 5

    # With authorized override
    with_override_loan_application_id = 7
    with_override_status = Constants::Status::APPLICATION_OVERRIDE_REJECTED
    with_override_reason = Constants::Status::REASON_1
    LoanAuthorization.record_authorization(with_override_loan_application_id, with_override_status, by_staff_id, performed_on, created_by, with_override_reason)
    LoanAuthorization.get_authorization(with_override_loan_application_id).should_not be_nil
    debugger
    LoanAuthorization.is_approved?(with_override_loan_application_id).should == false

    # Without authorize override
    without_override_loan_application_id = 8
    without_override_status = Constants::Status::APPLICATION_REJECTED
    without_override_reason = Constants::Status::REASON_2
    LoanAuthorization.record_authorization(without_override_loan_application_id, without_override_status, by_staff_id, performed_on, created_by, without_override_reason)
    LoanAuthorization.get_authorization(without_override_loan_application_id).should_not be_nil
    LoanAuthorization.is_approved?(without_override_loan_application_id).should == false
  end

end
