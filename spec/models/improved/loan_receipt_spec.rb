require File.join(File.dirname(__FILE__), '..', '..', "spec_helper")

describe LoanReceipt do

  before(:each) do
    @lending = Factory(:lending)
    @performed_at_id = Factory(:biz_location).id
    @accounted_at_id = Factory(:biz_location).id

    @principal_received_amount = 23000
    @interest_received_amount  = 2000
    @advance_received_amount   = 5000
    @advance_adjusted_amount   = 0
    @currency                  = :INR

    @allocation_amounts = {
        Constants::LoanAmounts::PRINCIPAL_RECEIVED => @principal_received_amount,
        Constants::LoanAmounts::INTEREST_RECEIVED  => @interest_received_amount,
        Constants::LoanAmounts::ADVANCE_RECEIVED   => @advance_received_amount,
        Constants::LoanAmounts::ADVANCE_ADJUSTED   => @advance_adjusted_amount
    }

    @allocation_values = Money.money_amounts_hash_to_money(@allocation_amounts, @currency)
  end

  it "should create a loan receipt as requested" do
    loan_receipt = LoanReceipt.record_allocation_as_loan_receipt(@allocation_values, @performed_at_id, @accounted_at_id, @lending, Date.today)
    loan_receipt.saved?.should be_true
  end

  it "should sum up the receipts on date as expected" do
    first = Date.parse('1947-08-15')
    thirty_first = first - 1

    first_principal = 2300; first_interest = 1275; first_advance = 793; first_advance_adjusted = 0
    first_allocation_values = Money.money_amounts_hash_to_money({:principal_received => first_principal, :interest_received => first_interest, :advance_received => first_advance, :advance_adjusted => first_advance_adjusted}, MoneyManager.get_default_currency)

    LoanReceipt.record_allocation_as_loan_receipt(first_allocation_values, @performed_at_id, @accounted_at_id, @lending, first)

    first_adjust_principal = 12; first_adjust_interest = 73; first_adjust_advance = 0; first_adjust_advance_adjusted = (12 + 73)
    first_adjust_allocation_values = Money.money_amounts_hash_to_money({:principal_received => first_adjust_principal, :interest_received => first_adjust_interest, :advance_received => first_adjust_advance, :advance_adjusted => first_adjust_advance_adjusted}, MoneyManager.get_default_currency)

    LoanReceipt.record_allocation_as_loan_receipt(first_adjust_allocation_values, @performed_at_id, @accounted_at_id, @lending, first)

    thirty_first_principal = 1243; thirty_first_interest = 1896; thirty_first_advance = 723; thirty_first_advance_adjusted = 0
    thirty_first_allocation_values = Money.money_amounts_hash_to_money({ :principal_received => thirty_first_principal, :interest_received => thirty_first_interest, :advance_received => thirty_first_advance, :advance_adjusted => thirty_first_advance_adjusted }, MoneyManager.get_default_currency)

    LoanReceipt.record_allocation_as_loan_receipt(thirty_first_allocation_values, @performed_at_id, @accounted_at_id, @lending, thirty_first)

    first_sum = LoanReceipt.sum_on_date(first)
    first_sum[:principal_received].amount.should == first_principal
    first_sum[:interest_received].amount.should == first_interest
    first_sum[:advance_received].amount.should == first_advance
    first_sum[:advance_adjusted].amount.should == first_adjust_advance_adjusted
    first_sum[:principal_received].currency.should == MoneyManager.get_default_currency

    thirty_first_sum = LoanReceipt.sum_on_date(thirty_first)
    thirty_first_sum[:principal_received].amount.should == thirty_first_principal
    thirty_first_sum[:interest_received].amount.should == thirty_first_interest
    thirty_first_sum[:advance_received].amount.should == thirty_first_advance
    thirty_first_sum[:advance_adjusted].amount.should == thirty_first_advance_adjusted
    thirty_first_sum[:principal_received].currency.should == MoneyManager.get_default_currency
  end

  it "should sum up the receipts till date as expected" do

    first = Date.parse('1869-10-02')
    thirty_first = first - 1

    first_principal = 2300; first_interest = 1275; first_advance = 793; first_advance_adjusted = 0
    first_allocation_values = Money.money_amounts_hash_to_money({:principal_received => first_principal, :interest_received => first_interest, :advance_received => first_advance, :advance_adjusted => first_advance_adjusted}, MoneyManager.get_default_currency)

    LoanReceipt.record_allocation_as_loan_receipt(first_allocation_values, @performed_at_id, @accounted_at_id, @lending, first)

    first_adjust_principal = 12; first_adjust_interest = 73; first_adjust_advance = 0; first_adjust_advance_adjusted = (12 + 73)
    first_adjust_allocation_values = Money.money_amounts_hash_to_money({:principal_received => first_adjust_principal, :interest_received => first_adjust_interest, :advance_received => first_adjust_advance, :advance_adjusted => first_adjust_advance_adjusted}, MoneyManager.get_default_currency)

    LoanReceipt.record_allocation_as_loan_receipt(first_adjust_allocation_values, @performed_at_id, @accounted_at_id, @lending, first)

    thirty_first_principal = 1243; thirty_first_interest = 1896; thirty_first_advance = 723; thirty_first_advance_adjusted = 0
    thirty_first_allocation_values = Money.money_amounts_hash_to_money({ :principal_received => thirty_first_principal, :interest_received => thirty_first_interest, :advance_received => thirty_first_advance, :advance_adjusted => thirty_first_advance_adjusted}, MoneyManager.get_default_currency)

    LoanReceipt.record_allocation_as_loan_receipt(thirty_first_allocation_values, @performed_at_id, @accounted_at_id, @lending, thirty_first)

    first_sum = LoanReceipt.sum_till_date(first)
    first_sum[:principal_received].amount.should == (first_principal + thirty_first_principal)
    first_sum[:interest_received].amount.should == (first_interest + thirty_first_interest)
    first_sum[:advance_received].amount.should == (first_advance + thirty_first_advance)
    first_sum[:advance_adjusted].amount.should == (first_advance_adjusted + first_adjust_advance_adjusted + thirty_first_advance_adjusted)
    first_sum[:principal_received].currency.should == MoneyManager.get_default_currency

    thirty_first_sum = LoanReceipt.sum_till_date(thirty_first)
    thirty_first_sum[:principal_received].amount.should == thirty_first_principal
    thirty_first_sum[:interest_received].amount.should == thirty_first_interest
    thirty_first_sum[:advance_received].amount.should == thirty_first_advance
    thirty_first_sum[:advance_adjusted].amount.should == thirty_first_advance_adjusted
    thirty_first_sum[:principal_received].currency.should == MoneyManager.get_default_currency

  end

end
