require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe AccountingRule do

  before(:each) do

  	MoneyCategory.create_default_money_categories
  	@loan_disbursement_category = MoneyCategory.resolve_money_category(Constants::Accounting::LOAN_DISBURSEMENT)
  	@loan_disbursement_category.should be_valid

  	@cash = Factory(:ledger)
    @loans_made = Factory(:ledger)

    @loan_disbursement_rule = AccountingRule.new(:name => "Loan disbursement", :money_category => @loan_disbursement_category)
    @loans_made_debit_rule = PostingRule.new(:effect => Constants::Accounting::DEBIT_EFFECT, :percentage => 100, :ledger => @loans_made, :accounting_rule => @loan_disbursement_rule)
    @cash_credit_rule = PostingRule.new(:effect => Constants::Accounting::CREDIT_EFFECT, :percentage => 100, :ledger => @cash, :accounting_rule => @loan_disbursement_rule)

    @loan_disbursement_rule.posting_rules.push(@loans_made_debit_rule)
    @loan_disbursement_rule.posting_rules.push(@cash_credit_rule)

    @loan_disbursement_rule.should be_valid
  end

  it "should not be valid without a money category" do
  	@loan_disbursement_rule.money_category = nil
  	@loan_disbursement_rule.should_not be_valid
  end

  it "should not be valid without rules for both debit and credit" do
  	@loan_disbursement_rule.posting_rules.clear
  	@loan_disbursement_rule.posting_rules.length.should == 0
  	@loan_disbursement_rule.should_not be_valid

  	@loan_disbursement_rule.posting_rules.push(@cash_credit_rule)
  	@loan_disbursement_rule.posting_rules.length.should == 1
  	@loan_disbursement_rule.should_not be_valid

  	@loan_disbursement_rule.posting_rules.push(@loans_made_debit_rule)
  	@loan_disbursement_rule.posting_rules.length.should == 2
  	@loan_disbursement_rule.should be_valid
  end

  it "should not be valid without the posting rules for debits and credits accounting for 100 percent of the amount" do 	
    loan_disbursement_rule = AccountingRule.new(:name => "Short credit loan disbursement", :money_category => @loan_disbursement_category)
    full_debit_rule = PostingRule.new(:effect => Constants::Accounting::DEBIT_EFFECT, :percentage => 100, :ledger => @loans_made, :accounting_rule => loan_disbursement_rule)
    short_credit_rule = PostingRule.new(:effect => Constants::Accounting::CREDIT_EFFECT, :percentage => 98, :ledger => @cash, :accounting_rule => loan_disbursement_rule)
    loan_disbursement_rule.posting_rules.push(full_debit_rule)
    loan_disbursement_rule.posting_rules.push(short_credit_rule)
    loan_disbursement_rule.posting_rules.length.should == 2
    loan_disbursement_rule.should_not be_valid

    loan_disbursement_rule = AccountingRule.new(:name => "Correct loan disbursement", :money_category => @loan_disbursement_category)
    full_debit_rule = PostingRule.new(:effect => Constants::Accounting::DEBIT_EFFECT, :percentage => 100, :ledger => @loans_made, :accounting_rule => loan_disbursement_rule)
    full_credit_rule = PostingRule.new(:effect => Constants::Accounting::CREDIT_EFFECT, :percentage => 100, :ledger => @cash, :accounting_rule => loan_disbursement_rule)
    loan_disbursement_rule.posting_rules.push(full_debit_rule)
    loan_disbursement_rule.posting_rules.push(full_credit_rule)
    loan_disbursement_rule.posting_rules.length.should == 2
    loan_disbursement_rule.should be_valid
  end

end