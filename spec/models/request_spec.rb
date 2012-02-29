require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Request do
  
  before(:all) do
    @request = Request.new()
  end

  it "should have status created for a newly created object/instance" do
    result = @request.get_status 
    result.should == :created
  end

  it "status should go from opened to sent" do
    result = @request.set_status(:sent)
    result.should be_true
  end

  it "status should go from sent to response_received" do
    result = @request.set_status(:response_received)
    result.should be_true
  end

  it "status should go from response_received to to_be_resent or not_to_be_resent " do 
    @request1 = @request
    @request2 = @request
    result1 = @request1.set_status(:to_be_present)
    result1.should be_true
    result2 = @request2.set_status(:not_to_be_present)
    result2.should be_true
  end

  it "status should go from to to_be_present/not_to_be_present to closed" do
    debugger
    result1 = @request1.set_status(:closed)
    result1.should be_true
    result2 = @request2.set_status(:closed)
    result2.should be_true
  end

end
