require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe OverlapReportRequest do

  before(:each) do
    @overlap_report_request = OverlapReportRequest.new
  end

  it "should be valid when created" do
    @overlap_report_request.should be_valid
  end

  it "should return the created status for a new report request" do
    @overlap_report_request.get_status.should == Constants::Status::CREATED
  end

  it "should raise an error if a status is requested to be set that is not supported" do
    lambda { @overlap_report_request.set_status(:try_illegal_status) }.should raise_error
  end

  it "should fail to set the status if the status value requested is the same as the current status of the request" do
    @overlap_report_request.set_status(Constants::Status::CREATED).should == false
  end

  it "should allow the status of a created request to be set to sent" do
    @overlap_report_request.set_status(:sent).should == :sent
  end

  it "should not allow the status of a sent request to be set to created"
  
  it "should not allow the status of a 'response_received' request to be set to created"


end