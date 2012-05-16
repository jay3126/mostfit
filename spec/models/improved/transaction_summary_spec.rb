require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe TransactionSummary do

  before(:each) do
    @branch = Factory(:branch)
    MoneyCategory.create_default_money_categories
    @disbursement_category = MoneyCategory.resolve_money_category(:loan_disbursement)

    @summary = TransactionSummary.new(:amount => 100, :currency => Constants::Accounting::DEFAULT_CURRENCY, :effective_on => Date.today - 10,
      :loan_id => 24,
      :branch_id => @branch.id, :branch_name => @branch.name, :loan_product_id => Constants::Accounting::NOT_A_VALID_ASSET_TYPE_ID,
      :fee_type_id => Constants::Accounting::NOT_A_VALID_INCOME_TYPE_ID, :money_category => @disbursement_category
    )
  end

  it "should not be valid without specifying an amount" do
    @summary.amount = nil
    @summary.should_not be_valid
  end

end