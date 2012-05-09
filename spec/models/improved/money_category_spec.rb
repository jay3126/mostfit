require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe MoneyCategory do

  before(:all) do
    MoneyCategory.create_default_money_categories
    @money_categories = MoneyCategory.all
  end

  it "should have at least one value for account_type category to be valid" do
    first_category = @money_categories.first

    first_category.asset_category = Constants::Accounting::NOT_AN_ASSET
    first_category.liability_category = Constants::Accounting::NOT_A_LIABILITY
    first_category.income_category = Constants::Accounting::NOT_AN_INCOME
    first_category.expense_category = Constants::Accounting::NOT_AN_EXPENSE

    first_category.should_not be_valid
  end

end