require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe ChequeLeaf do

  before(:each) do
	ChequeLeaf.all.destroy!
	ChequeLeaf.create!(:serial_no => 123456, :created_by_user_id => 1, :created_at => Time.now, :bank_account_id => 123)
    @leaf= ChequeLeaf.first
  end
 
  
  
  it "should not be valid if cheque leaf of the same serial number for same bank, and same branch are already in the cheque master" do
    @new_leaf= ChequeLeaf.new(:serial_no => 123456, :bank_account_id => 123)
    @new_leaf.save.should_not be_true
  end
  
  it "should not be valid if :account_no is not valid" do
    @leaf.bank_account_id = nil
    @leaf.should_not be_valid
  end
  
  it "should not be valid if :serial_no is not set or not a valid number" do
    @leaf.serial_no = nil
    @leaf.should_not be_valid
  end
  
   
  it "should not be valid if :serial_no is not valid" do
	@leaf.serial_no = "abc123"
	@leaf.should_not be_valid
  end
  

end
