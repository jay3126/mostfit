require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LoanApplication do

  before(:each) do
    @lap = LoanApplication.new
  end

  it "should have a new status when created" do
    @lap.get_status.should == Constants::Status::NEW_STATUS
  end

  it "should not be approved when created" do
    @lap.is_approved?.should == false
  end

end
