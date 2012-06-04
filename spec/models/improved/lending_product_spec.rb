require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LendingProduct do

  before(:each) do

    @name = 'Popular Loan'
    @standard_loan_money_amount = Money.new(10000, :INR)
    @total_interest_applicable_money_amount = Money.new(2000, :INR)
    @annual_interest_rate = 25.99
    @repayment_frequency = MarkerInterfaces::Recurrence::WEEKLY
    @tenure = 3
    @allocation_strategy = Constants::LoanAmounts::EARLIEST_INTEREST_FIRST_THEN_EARLIEST_PRINCIPAL_ALLOCATION
    @principal_amounts = [Money.new(2000, :INR), Money.new(3000, :INR), Money.new(5000, :INR)]
    @interest_amounts = [Money.new(800, :INR), Money.new(700, :INR), Money.new(500, :INR)]

    @lp = LendingProduct.create_lending_product(
        @name,
        @standard_loan_money_amount,
        @total_interest_applicable_money_amount,
        @annual_interest_rate,
        @repayment_frequency,
        @tenure,
        @allocation_strategy,
        @principal_amounts,
        @interest_amounts
    )

    @lp.id.should_not be_nil
  end

  it "should not be valid without name" do
    @lp.name = nil; @lp.should_not be_valid
  end

  it "should not be valid without amount" do
    @lp.amount = nil; @lp.should_not be_valid
  end

  it "should not be valid without currency" do
    @lp.currency = nil; @lp.should_not be_valid
  end

  it "should not be valid without interest rate" do
    @lp.interest_rate = nil; @lp.should_not be_valid
  end

  it "should not be valid without repayment frequency" do
    @lp.repayment_frequency = nil; @lp.should_not be_valid
  end

  it "should not be valid without tenure" do
    @lp.tenure = nil; @lp.should_not be_valid
  end

  it "should have a loan schedule template created" do
    @lp.loan_schedule_template.should_not be_nil
  end

end