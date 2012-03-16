require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe ClientVerification do

  before(:all) do
    @time_datum = Time.now
    @on_date = Date.today
    @by_p_staff_id = 3;
    @by_x_user_id = 29;
    @counter = 1
  end

  it "should record a CPV1 approved when requested" do
    loan_application_id = ((Time.now - @time_datum) * 1000).to_i
    ClientVerification.record_CPV1_approved(loan_application_id, @by_p_staff_id, @on_date, @by_x_user_id)
    ClientVerification.is_CPV1_verified?(loan_application_id).should == true
  end

  it "should record a CPV1 rejected when requested" do
    loan_application_id = ((Time.now - @time_datum) * 1000).to_i
    ClientVerification.record_CPV1_rejected(loan_application_id, @by_p_staff_id, @on_date, @by_x_user_id)
    ClientVerification.is_CPV1_verified?(loan_application_id).should == false
  end
  
  it "should not allow different statuses to be recorded for a CPV1 for a loan application" do
    loan_application_id = ((Time.now - @time_datum) * 1000).to_i

    ClientVerification.record_CPV1_rejected(loan_application_id, @by_p_staff_id, @on_date, @by_x_user_id)
    ClientVerification.is_CPV1_verified?(loan_application_id).should == false

    ClientVerification.record_CPV1_approved(loan_application_id, @by_p_staff_id, @on_date, @by_x_user_id)
    ClientVerification.is_CPV1_verified?(loan_application_id).should == false
  end

  it "should disallow recording CPV2 on a loan application that has no CPV1" do
    loan_application_id = ((Time.now - @time_datum) * 1000).to_i

    ClientVerification.get_CPV1_status(loan_application_id).should == Constants::Verification::NOT_VERIFIED
    ClientVerification.get_CPV2_status(loan_application_id).should == Constants::Verification::NOT_VERIFIED

    ClientVerification.record_CPV2_approved(loan_application_id, @by_p_staff_id, @on_date, @by_x_user_id)
    ClientVerification.get_CPV2_status(loan_application_id).should == Constants::Verification::NOT_VERIFIED

    ClientVerification.record_CPV2_rejected(loan_application_id, @by_p_staff_id, @on_date, @by_x_user_id)
    ClientVerification.get_CPV2_status(loan_application_id).should == Constants::Verification::NOT_VERIFIED
  end

  it "should tell that CPV process is incomplete when no CPVs are recorded" do
    #when no CPV is recorded
    loan_application_id = ((Time.now - @time_datum) * 1000).to_i
    ClientVerification.get_CPVs(loan_application_id).should == []
    ClientVerification.is_cpv_complete?(loan_application_id).should == false
  end

  it "should tell that CPV process is incomplete when only CPV1 is recorded" do
    #when only CPV1 is recorded as approved
    loan_application_id = ((Time.now - @time_datum) * 1000).to_i
    ClientVerification.record_CPV1_approved(loan_application_id, @by_p_staff_id, @on_date, @by_x_user_id)
    ClientVerification.is_cpv_complete?(loan_application_id).should == false

  end
  
  it "should tell that CPV is process is complete when CPV1 is rejected" do
     loan_application_id = ((Time.now - @time_datum) * 1000).to_i
     ClientVerification.record_CPV1_rejected(loan_application_id, @by_p_staff_id, @on_date, @by_x_user_id)
     ClientVerification.is_cpv_complete?(loan_application_id).should == true
  end

 
  it "should tell that CPV process is complete when CPV2 has been recorded" do
    #when both CPV1 and CPV2 are recorded 
    loan_application_id = ((Time.now - @time_datum) * 1000).to_i
    ClientVerification.record_CPV1_approved(loan_application_id, @by_p_staff_id, @on_date, @by_x_user_id)
    ClientVerification.record_CPV2_rejected(loan_application_id, @by_p_staff_id, @on_date, @by_x_user_id)
    ClientVerification.is_cpv_complete?(loan_application_id).should == true

    loan_application_id = ((Time.now - @time_datum) * 1000).to_i
    ClientVerification.record_CPV1_approved(loan_application_id, @by_p_staff_id, @on_date, @by_x_user_id)
    ClientVerification.record_CPV2_approved(loan_application_id, @by_p_staff_id, @on_date, @by_x_user_id)
    ClientVerification.is_cpv_complete?(loan_application_id).should == true
  end

  it "should be convertible into a rightly-formed ClientVerificationInfo object" do
     loan_application_id = ((Time.now - @time_datum) * 1000).to_i
     ClientVerification.record_CPV1_approved(loan_application_id, @by_p_staff_id, @on_date, @by_x_user_id)
     cpv1 = ClientVerification.get_CPV1(loan_application_id)[0] #because it returns an array
     cpv1Info = cpv1.to_info
     
     cpv1Info.loan_application_id.should == cpv1.loan_application_id
     cpv1Info.verification_type.should == cpv1.verification_type
     cpv1Info.verification_status.should == cpv1.verification_status
     cpv1Info.verified_by_staff_id.should == cpv1.verified_by_staff_id
     cpv1Info.verified_on_date.should == cpv1.verified_on_date
     cpv1Info.created_by_user_id.should == cpv1.created_by_user_id
     cpv1Info.created_at.should == cpv1.created_at

  end
end
