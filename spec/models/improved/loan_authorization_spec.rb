require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe LoanAuthorization do

  before(:all) do
    #TBD
    # Create a factory for loan applications
  end

  it "should not be valid without an override reason when the authorization is an override"

  it "should not be valid with an override reason when the authorization is an override"

  it "should return the correct status as authorized approved when it is authorized approved with or without an override"

  it "should return the correct status as authorized rejected when it is authorized rejected with or without an override"

  it "should find the authorization for a loan application when an authorization is recorded"

  it "should return nil for a loan application when no authorization has been recorded"

end