require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe PostingRule do

  before(:each) do
  	@open_on = Date.parse("2012-01-01")

  	MoneyCategory.create_default_money_categories
  	@loan_disbursement_category = MoneyCategory.resolve_money_category(Constants::Accounting::LOAN_DISBURSEMENT)
  	@loan_disbursement_category.should be_valid

  	@cash = Ledger.new(:name => "Cash", :account_type => Constants::Accounting::ASSETS, :open_on => @open_on, 
  	  :opening_balance_amount => 0, :opening_balance_currency => Constants::Accounting::DEFAULT_CURRENCY, :opening_balance_effect => Constants::Accounting::DEBIT_EFFECT
  	)
    @loans_made = Ledger.new(:name => "Loans made", :account_type => Constants::Accounting::ASSETS, :open_on => @open_on,
      :opening_balance_amount => 0, :opening_balance_currency => Constants::Accounting::DEFAULT_CURRENCY, :opening_balance_effect => Constants::Accounting::DEBIT_EFFECT
    )

    @loan_disbursement_rule = AccountingRule.new(:name => "Loan disbursement", :money_category => @loan_disbursement_category)  	
    @debit_rule = PostingRule.new(:effect => Constants::Accounting::DEBIT_EFFECT, :percentage => 100, :accounting_rule => @loan_disbursement_rule, :ledger => @loans_made)
    @credit_rule = PostingRule.new(:effect => Constants::Accounting::CREDIT_EFFECT, :percentage => 100, :accounting_rule => @loan_disbursement_rule, :ledger => @cash)
  end

  it "should not be valid without a valid accounting effect" do
  	@debit_rule.effect = nil
  	@debit_rule.should_not be_valid
  end

  it "should not be valid without specifying a ledger to post to" do
  	@debit_rule.ledger = nil
  	@debit_rule.should_not be_valid
  end

  it "given a money amount, it should return the correct posting information" do
    amount = 73
    currency = Constants::Accounting::DEFAULT_CURRENCY
    percentage = @debit_rule.percentage
    expected_posting_amount = (amount * percentage)/100
    effect = @debit_rule.effect
    ledger = @debit_rule.ledger

    posting_info = @debit_rule.to_posting_info(amount, currency)
    posting_info.amount.should == expected_posting_amount
    posting_info.currency.should == currency
    posting_info.effect.should == effect
    posting_info.ledger.should == ledger
  end

end