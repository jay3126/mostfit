require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe Lending do

  before(:all) do
    @from_lending_product = Factory(:lending_product)
  end

  it "should have a status of new" do
    new_loan = Lending.new
    loan_status = new_loan.get_current_status
    loan_status.should == Constants::Loan::NEW
  end

  it "should create a new loan as expected" do
    lan = 'my_unique_lan'
    for_amount = Money.new(1000000, :INR);
    for_borrower_id = 123
    applied_on_date = Date.parse('2012-05-01')
    scheduled_disbursal_date = applied_on_date + 7
    scheduled_first_repayment_date = scheduled_disbursal_date + 7
    repayment_frequency = MarkerInterfaces::Recurrence::WEEKLY;
    tenure = 52
    administered_at_origin = 768
    accounted_at_origin = 1024
    applied_by_staff = 21
    recorded_by_user = 23

    new_loan = Lending.create_new_loan(for_amount, repayment_frequency, tenure, @from_lending_product, for_borrower_id, administered_at_origin, accounted_at_origin, applied_on_date, scheduled_disbursal_date, scheduled_first_repayment_date, applied_by_staff, recorded_by_user, lan)

    new_loan.lan.should                    == lan
    new_loan.applied_amount.should         == for_amount.amount
    new_loan.currency.should               == for_amount.currency
    new_loan.for_borrower_id.should        == for_borrower_id
    new_loan.applied_on_date.should        == applied_on_date
    new_loan.approved_amount.should        == nil
    new_loan.repayment_frequency.should    == repayment_frequency
    new_loan.tenure.should                 == tenure
    new_loan.administered_at_origin.should == administered_at_origin
    new_loan.accounted_at_origin.should    == accounted_at_origin
    new_loan.applied_by_staff.should       == applied_by_staff
    new_loan.recorded_by_user.should       == recorded_by_user
    new_loan.status.should                 == Constants::Loan::NEW
    new_loan.lending_product.should        == @from_lending_product

    new_loan.scheduled_disbursal_date.should       == scheduled_disbursal_date
    new_loan.scheduled_first_repayment_date.should == scheduled_first_repayment_date
  end

end
