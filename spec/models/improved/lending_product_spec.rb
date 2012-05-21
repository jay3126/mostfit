require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LendingProduct do

  before(:each) do
    @lp = LendingProduct.new(
      :name                => 'Popular Loan Product',
      :amount              => 10000,
      :currency            => Constants::Money::INR,
      :interest_rate       => 25.99,
      :repayment_frequency => MarkerInterfaces::Recurrence::WEEKLY,
      :tenure              => 46,
      :repayment_allocation_strategy => Constants::LoanAmounts::EARLIEST_INTEREST_FIRST_THEN_EARLIEST_PRINCIPAL_ALLOCATION
    )
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

end