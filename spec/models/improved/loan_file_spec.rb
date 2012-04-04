require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LoanFile do
  
  before(:all) do
    @staff_member = Factory(:staff_member)
    @user = Factory(:user)
    @center = Factory(:center)
    @branch = Factory(:branch)
    @lap = Factory(:loan_application)
  end
  
  before(:each) do 
    LoanFile.all.destroy!
    @lf = LoanFile.new()
    @lf.at_branch_id = 1
    @lf.at_center_id = 1
    @lf.for_cycle_number = 1
    @lf.scheduled_disbursal_date = Date.today + 2
    @lf.scheduled_first_payment_date = Date.today + 5
    @lf.created_by_staff_id = 3
    @lf.created_on = Date.today + 9
    @lf.created_by = 9
    @lf.should be_valid
    @lf.save.should be_true
    lap_id = [@lap.id]
    LoanApplication.add_to_loan_file(@lf.loan_file_identifier, @lf.at_branch_id, @lf.at_center_id,
      @lf.for_cycle_number, @lf.created_by_staff_id, @lf.created_on, @lf.created_by, *lap_id)
  end

  it "should have a branch and center specified when created"

  it "should have a created_on date specified"

  it "should have a staff member specified that created the loan file"

  it "should have a user that created the loan file and the timestamp of creation"

  it "should have a loan file identifier that adheres to a specific mnemonic format"

  it "should return correct loan files for a particular branch or center" do
    loan_files = LoanFile.locate_loan_files_at_center_at_branch_for_cycle(@lf.at_branch_id, @lf.at_center_id, @lf.for_cycle_number)
    loan_files.nil?.should be_false
    loan_files.empty?.should be_false
    loan_files.is_a?(Array).should be_true
  end

end
