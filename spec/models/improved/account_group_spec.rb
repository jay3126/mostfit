require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe AccountGroup do

  before(:each) do
    @account_group = Factory(:account_group)
  end

  it "should not be valid without a name" do
    @account_group.name = nil
    @account_group.should_not be_valid
  end

  it "should not be valid without an account type" do
    @account_group.account_type = nil
    @account_group.should_not be_valid
  end

end