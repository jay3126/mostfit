require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe Lending do

  before(:all) do
    @from_lending_product = Factory(:lending_product)

    @principal_and_interest_amounts = {}

    @principal_amounts            = [170.18, 171.03, 171.88, 172.74, 173.60, 174.46, 175.33, 176.21, 177.08, 177.97, 178.85, 179.74, 180.64, 181.54, 182.44, 183.35, 184.27, 185.18, 186.11, 187.03, 187.97, 188.90, 189.84, 190.79, 191.74, 192.69, 193.65, 194.62, 195.59, 196.56, 197.54, 198.53, 199.52, 200.51, 201.51, 202.51, 203.52, 204.53, 205.55, 206.58, 207.61, 208.64, 209.68, 210.73, 211.77, 212.83, 213.89, 214.96, 216.03, 217.10, 218.18, 146.30]
    @principal_money_amounts      = MoneyManager.get_money_instance(*@principal_amounts)
    zero_money_amount             = Money.zero_money_amount(Constants::Money::DEFAULT_CURRENCY)
    @total_principal_money_amount = @principal_money_amounts.inject(zero_money_amount) { |sum, money_amt| sum + money_amt }

    @interest_amounts            = [49.82, 48.97, 48.12, 47.26, 46.40, 45.54, 44.67, 43.79, 42.92, 42.03, 41.15, 40.26, 39.36, 38.46, 37.56, 36.65, 35.73, 34.82, 33.89, 32.97, 32.03, 31.10, 30.16, 29.21, 28.26, 27.31, 26.35, 25.38, 24.41, 23.44, 22.46, 21.47, 20.48, 19.49, 18.49, 17.49, 16.48, 15.47, 14.45, 13.42, 12.39, 11.36, 10.32, 9.27, 8.23, 7.17, 6.11, 5.04, 3.97, 2.90, 1.82, 0.73]
    @interest_money_amounts      = MoneyManager.get_money_instance(*@interest_amounts)
    zero_money_amount            = Money.zero_money_amount(Constants::Money::DEFAULT_CURRENCY)
    @total_interest_money_amount = @interest_money_amounts.inject(zero_money_amount) { |sum, money_amt| sum + money_amt }

    1.upto(@principal_amounts.length) { |num|
      principal_and_interest                                           = { }
      principal_and_interest[Constants::Transaction::PRINCIPAL_AMOUNT] = @principal_money_amounts[num - 1]
      principal_and_interest[Constants::Transaction::INTEREST_AMOUNT]  = @interest_money_amounts[num - 1]
      @principal_and_interest_amounts[num]                             = principal_and_interest
    }

    @principal_and_interest_amounts[0] = {
        Constants::Transaction::PRINCIPAL_AMOUNT => @total_principal_money_amount,
        Constants::Transaction::INTEREST_AMOUNT  => @total_interest_money_amount
    }

    @name = 'test template 1'

    @lst = LoanScheduleTemplate.create_schedule_template(@name, @total_principal_money_amount, @total_interest_money_amount, @principal_money_amounts.length, MarkerInterfaces::Recurrence::WEEKLY, @from_lending_product, @principal_and_interest_amounts)

    lan = "#{DateTime.now}"
    for_amount = @total_principal_money_amount
    for_borrower_id = 123
    applied_on_date = Date.parse('2012-05-01')
    scheduled_disbursal_date = applied_on_date + 7
    scheduled_first_repayment_date = scheduled_disbursal_date + 7
    repayment_frequency = MarkerInterfaces::Recurrence::WEEKLY
    tenure = 52
    administered_at_origin = 768
    accounted_at_origin = 1024
    applied_by_staff = 21
    recorded_by_user = 23

    @loan = Lending.create_new_loan(for_amount, repayment_frequency, tenure, @from_lending_product, for_borrower_id, administered_at_origin, accounted_at_origin, applied_on_date, scheduled_disbursal_date, scheduled_first_repayment_date, applied_by_staff, recorded_by_user, lan)
    @loan.saved?.should == true
  end

  it "should have a status of new" do
    new_loan = Lending.new
    loan_status = new_loan.get_current_status
    loan_status.should == Constants::Loan::NEW
  end

  it "should create a new loan as expected" do
    lan = "my_unique_lan #{DateTime.now}"
    for_amount = Money.new(1000000, :INR)
    for_borrower_id = 123
    applied_on_date = Date.parse('2012-05-01')
    scheduled_disbursal_date = applied_on_date + 7
    scheduled_first_repayment_date = scheduled_disbursal_date + 7
    repayment_frequency = MarkerInterfaces::Recurrence::WEEKLY
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

  context "when no repayments have been made on the loan" do

    it "total principal repaid till date should be zero" do
      @loan.total_principal_repaid.should == Money.zero_money_amount(Constants::Money::DEFAULT_CURRENCY)
    end

    it "total interest received till date should be zero" do
      @loan.total_interest_received.should == Money.zero_money_amount(Constants::Money::DEFAULT_CURRENCY)
    end

  end

=begin
  context "the date is the first scheduled repayment date on the loan" do

    it "the loan due status is due on the date"

    it "if there were any repayments received earlier and accumulated as advances,
they are adjusted against the amounts due on the first scheduled repayment date and allocated accordingly"

    it "the loan balance due on the date is as per the schedule on the date"

  end

  context "no repayment was received on the first scheduled repayment date and
for a few days until a date preceding the next scheduled repayment date" do

    it "the loan due status is OVERDUE on the next day and on future dates until a repayment is received that equals the loan balances due on the first scheduled repayment date"

  end

  context "no repayment was received since disbursement until a future date that falls ahead of the second schedule date,
and the repayment received is under the amount expected as per the first scheduled repayment date" do

    it "the loan due status is OVERDUE on each such date"

    it "a single first repayment received on any such date that is less than the loan schedule balance at the first scheduled repayment date is allocated towards principal and interest"

    it "any number of further repayments received on any such date that are collectively less than the loan schedule balance at the first scheduled repayment date are all allocated towards principal and interest and the loan due status remainds OVERDUE"

    it "if one or more single repayment received that exceeds the loan scheduled balance on the first scheduled repayment date after the date, then the loan due status is now UDE, and all repayents are allocated against principal and interest"

  end

  context " a repayment is received on the scheduled repayment date" do

    it "the loan due status is computed as overdue"

    it "the loan due status is computed as due"

  end

  context "the loan balance for anticipated repayment is to be considered on a date that is not a schedule date" do

    it "if the loan is overdue, the schedule balance to be considered for anticipated repayment is per the immediately previous scheduled repayment"

    it "if the loan is not due, the schedule balance to be considered for anticipated repayment is per the immediately next scheduled repayment"

  end

  context "the date is before the disbursement date" do

    it "no receipts can be accepted towards the loan"

    it "the loan status is not yet disbursed"

    it "the loan balances are as per the loan base schedule"

  end

  context "the loan is disbursed on the date" do

    it "the loan amount disbursed cannot exceed the loan amount sanctioned"

    it "the loan status is disbursed"

    it "a payment transactions is recorded for the extent of disbursement"

    it "the date of first scheduled repayment is recorded"

    it "the loan base schedule has dates that begin with the date of first scheduled repayment,
followed by dates as per the loan base schedule"

  end

  context "the date is before the scheduled first repayment date" do

    it "the loan status is disbursed"

    it "the loan due status should be not due"

    it "any repayments received are accumulated as advance"

    it "the scheduled first repayment date does not change despite the event that any repayments are received"

  end
=end

end


