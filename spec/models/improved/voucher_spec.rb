require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe Voucher do

  before(:all) do
    @open_on = ACCOUNTING_DATE_BEGINS
    @accounts_chart = Factory(:accounts_chart)

    ledger_attributes = Factory.attributes_for(:ledger)
    #ASSETS
    @cash = Factory.create(:ledger, ledger_attributes.merge(:name => "Cash", :account_type => Constants::Accounting::ASSETS, :opening_balance_effect => Constants::Accounting::DEBIT_EFFECT))
    @loans_made = Factory.create(:ledger, ledger_attributes.merge(:name => "Loans made", :account_type => Constants::Accounting::ASSETS, :opening_balance_effect => Constants::Accounting::DEBIT_EFFECT))
    @bank_account = Factory.create(:ledger, ledger_attributes.merge(:name => "Bank Account", :account_type => Constants::Accounting::ASSETS, :opening_balance_effect => Constants::Accounting::DEBIT_EFFECT))

    #INCOMES
    @interest_income = Factory.create(:ledger, ledger_attributes.merge(:name => "Interest income", :account_type => Constants::Accounting::INCOMES, :opening_balance_effect => Constants::Accounting::CREDIT_EFFECT))
    @fee_income = Factory.create(:ledger, ledger_attributes.merge(:name => "Fee income", :account_type => Constants::Accounting::INCOMES, :opening_balance_effect => Constants::Accounting::CREDIT_EFFECT))

    #EXPENSES
    @salaries = Factory.create(:ledger, ledger_attributes.merge(:name => "Salaries", :account_type => Constants::Accounting::EXPENSES, :opening_balance_effect => Constants::Accounting::DEBIT_EFFECT))
    
    #LIABILITIES
    @loans_taken = Factory.create(:ledger, ledger_attributes.merge(:name => "Loans taken", :account_type => Constants::Accounting::LIABILITIES, :opening_balance_effect => Constants::Accounting::CREDIT_EFFECT))
  end

  before(:each) do
    @voucher = Voucher.new(:total_amount => 100, :currency => :INR, :effective_on => @open_on)

    @cash_debit = LedgerPosting.new(:voucher => @voucher, :effective_on => @voucher.effective_on, :ledger => @cash, :amount => 100, :currency => :INR, :effect => Constants::Accounting::DEBIT_EFFECT)
    @cash.ledger_postings.push(@cash_debit)
    
    @principal_credit = LedgerPosting.new(:voucher => @voucher, :effective_on => @voucher.effective_on, :ledger => @loans_made, :amount => 80, :currency => :INR, :effect => Constants::Accounting::CREDIT_EFFECT)
    @loans_made.ledger_postings.push(@principal_credit)
    
    @interest_credit = LedgerPosting.new(:voucher => @voucher, :effective_on => @voucher.effective_on, :ledger => @interest_income, :amount => 15, :currency => :INR, :effect => Constants::Accounting::CREDIT_EFFECT)
    @interest_income.ledger_postings.push(@interest_credit)
    
    @fee_credit = LedgerPosting.new(:voucher => @voucher, :effective_on => @voucher.effective_on, :ledger => @fee_income, :amount => 5, :currency => :INR, :effect => Constants::Accounting::CREDIT_EFFECT)
    @fee_income.ledger_postings.push(@fee_credit)
    
    @voucher.ledger_postings.push(@cash_debit)
    @voucher.ledger_postings.push(@principal_credit)
    @voucher.ledger_postings.push(@interest_credit)
    @voucher.ledger_postings.push(@fee_credit)    
  end

  it "should not be valid without a total amount" do
    @voucher.total_amount = nil
    @voucher.should_not be_valid
  end

  it "should not be valid without effective date" do
    @voucher.effective_on = nil
    @voucher.should_not be_valid
  end

  it "should not be valid unless at least two postings are present" do
    @voucher.ledger_postings.clear
    @voucher.ledger_postings.push(@cash_debit)
    @voucher.should_not be_valid
  end
 
  it "should not be valid unless each posting is individually valid" do
  end
 
  it "should not be valid unless all postings taken together are valid" do
  end

  it "should not be valid unless postings are all to unique accounts" do
    voucher = Voucher.new(:total_amount => 100, :currency => :INR, :effective_on => @open_on)
    cash_debit_one = LedgerPosting.new(:voucher => voucher, :effective_on => voucher.effective_on, :ledger => @cash, :amount => 50, :currency => :INR, :effect => Constants::Accounting::DEBIT_EFFECT)
    voucher.ledger_postings.push(cash_debit_one)
    cash_debit_two = LedgerPosting.new(:voucher => voucher, :effective_on => voucher.effective_on, :ledger => @cash, :amount => 50, :currency => :INR, :effect => Constants::Accounting::DEBIT_EFFECT)
    voucher.ledger_postings.push(cash_debit_two)
    loans_made_credit = LedgerPosting.new(:voucher => voucher, :effective_on => voucher.effective_on, :ledger => @loans_made, :amount => 100, :currency => :INR, :effect => Constants::Accounting::CREDIT_EFFECT)
    voucher.ledger_postings.push(loans_made_credit)
    voucher.should_not be_valid
  end

  it "should not be valid unless postings add up" do
    voucher = Voucher.new(:total_amount => 100, :currency => :INR, :effective_on => @open_on)
    cash_debit = LedgerPosting.new(:voucher => voucher, :effective_on => voucher.effective_on, :ledger => @cash, :amount => 99, :currency => :INR, :effect => Constants::Accounting::DEBIT_EFFECT)
    loans_made_credit = LedgerPosting.new(:voucher => voucher, :effective_on => voucher.effective_on, :ledger => @loans_made, :amount => 100, :currency => :INR, :effect => Constants::Accounting::CREDIT_EFFECT)
    voucher.ledger_postings.push(cash_debit)
    voucher.ledger_postings.push(loans_made_credit)
    voucher.should_not be_valid
  end

  it "should not be valid unless all postings post to accounts on the same chart of accounts" do
    new_cash = Ledger.new(:accounts_chart => @accounts_chart, :name => "New cash", :account_type => Constants::Accounting::ASSETS, :open_on => @open_on, :opening_balance_amount => 0, :opening_balance_currency => :INR, :opening_balance_effect => Constants::Accounting::DEBIT_EFFECT)
    voucher = Voucher.new(:total_amount => 100, :currency => :INR, :effective_on => @open_on)
    mismatched_cash_debit = LedgerPosting.new(:voucher => voucher, :effective_on => voucher.effective_on, :ledger => new_cash, :amount => 100, :currency => :INR, :effect => Constants::Accounting::DEBIT_EFFECT)
    loans_made_credit = LedgerPosting.new(:voucher => voucher, :effective_on => voucher.effective_on, :ledger => @loans_made, :amount => 100, :currency => :INR, :effect => Constants::Accounting::CREDIT_EFFECT)
    voucher.ledger_postings.push(mismatched_cash_debit)
    voucher.ledger_postings.push(loans_made_credit)
    voucher.should_not be_valid
  end
end
