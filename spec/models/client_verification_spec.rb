require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe ClientVerification do

  before(:each) do
    @cpv1 = ClientVerification.new
    @on_date = Date.today
    @by_p_staff_id = 3; @by_q_staff_id = 7
    @by_x_user_id = 29
  end

  it "status should be set as expected" do
    @cpv1.get_status.should == Constants::Verification::NOT_VERIFIED
    @cpv1.set_status(Constants::Verification::VERIFIED_REJECTED, @on_date, @by_p_staff_id, @by_x_user_id)
    @cpv1.get_status.should == Constants::Verification::VERIFIED_REJECTED

    @cpv1.set_status(Constants::Verification::VERIFIED_ACCEPTED, @on_date, @by_q_staff_id, @by_x_user_id)
    @cpv1.get_status.should == Constants::Verification::VERIFIED_ACCEPTED
  end

end