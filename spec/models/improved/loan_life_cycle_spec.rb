require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

class LoanLifeCycleImpl
  include LoanLifeCycle

  attr_reader :status
  def initialize(status); @status = status; end

  def set_status(status); @status = status; end
end

describe LoanLifeCycle do

  it "should return the current status as expected" do
    new_loan = LoanLifeCycleImpl.new(LoanLifeCycle::NEW_LOAN_STATUS)
    new_loan.current_loan_status.should == LoanLifeCycle::NEW_LOAN_STATUS

    new_loan.set_status(LoanLifeCycle::APPROVED_LOAN_STATUS)
    new_loan.current_loan_status.should == LoanLifeCycle::APPROVED_LOAN_STATUS

    new_loan.set_status(LoanLifeCycle::DISBURSED_LOAN_STATUS)
    new_loan.current_loan_status.should == LoanLifeCycle::DISBURSED_LOAN_STATUS
  end

  it "should return the disbursed status as expected" do
    new_loan = LoanLifeCycleImpl.new(LoanLifeCycle::NEW_LOAN_STATUS)
    new_loan.current_loan_status.should == LoanLifeCycle::NEW_LOAN_STATUS
    new_loan.is_disbursed?.should be_false
    
    new_loan.set_status(LoanLifeCycle::APPROVED_LOAN_STATUS)
    new_loan.current_loan_status.should == LoanLifeCycle::APPROVED_LOAN_STATUS
    new_loan.is_disbursed?.should be_false
    
    new_loan.set_status(LoanLifeCycle::DISBURSED_LOAN_STATUS) 
    new_loan.current_loan_status.should == LoanLifeCycle::DISBURSED_LOAN_STATUS
    new_loan.is_disbursed?.should be_true

    new_loan.set_status(LoanLifeCycle::REPAID_LOAN_STATUS)
    new_loan.current_loan_status.should == LoanLifeCycle::REPAID_LOAN_STATUS
    new_loan.is_disbursed?.should be_true
  end

end