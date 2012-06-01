require File.join( File.dirname(__FILE__), '..', '..', 'spec_helper')

describe Ledger do

  before(:each) do
    @cash = Factory(:ledger)
    @accounts_chart = Factory(:accounts_chart)
    @open_date = Date.parse('2011-04-01')
  end
 
  it "should have a name" do
    @cash.name = nil
    @cash.should_not be_valid
  end

  it "should have an account type" do
    @cash.account_type = nil
    @cash.should_not be_valid
  end

  it "should have an open date" do
    @cash.open_on = nil
    @cash.should_not be_valid
  end

  it "should have an opening balance amount" do
    @cash.opening_balance_amount = nil
    @cash.should_not be_valid
  end

  it "should have an opening balance currency" do
    @cash.opening_balance_currency = nil
    @cash.should_not be_valid
  end

  it "should have an opening balance effect" do
    @cash.opening_balance_effect = nil
    @cash.should_not be_valid
  end

  it "should belong to an accounts chart to be valid" do
    @cash.accounts_chart = nil
    @cash.should_not be_valid
  end

  it "should return an opening balance and date" do
    open_date = Date.today
    opening_balance_amount, opening_balance_currency, opening_balance_effect = 100, :INR, :debit
    test_ledger = Ledger.new(:accounts_chart => @accounts_chart, :name => "Test", :account_type => :assets, :open_on => open_date, :opening_balance_amount => opening_balance_amount, :opening_balance_currency => opening_balance_currency, :opening_balance_effect => opening_balance_effect, :accounts_chart => @accounts_chart)
    test_ledger.should be_valid
 
    opening_balance_and_date = test_ledger.opening_balance_and_date
    opening_balance = opening_balance_and_date.first; open_on = opening_balance_and_date.last
    [opening_balance_amount, opening_balance_currency, opening_balance_effect].should == opening_balance.balance
    open_date.should eql open_on
  end

  it "the balance on a ledger for no cost center is the cumulative effect of postings to the ledger from vouchers that have no cost center" do
    @test_asset_account = Ledger.create(:accounts_chart => @accounts_chart, :name => "Test asset account #{DateTime.now}", :account_type => Constants::Accounting::ASSETS, :open_on => @open_date, :opening_balance_amount => 0, :opening_balance_currency => Constants::Money::DEFAULT_CURRENCY, :opening_balance_effect => Constants::Accounting::DEBIT_EFFECT, :accounts_chart => @accounts_chart)
    @test_asset_account.saved?.should be_true

    @test_liability_account = Ledger.create(:accounts_chart => @accounts_chart, :name => "Test liability account #{DateTime.now}", :account_type => Constants::Accounting::LIABILITIES, :open_on => @open_date, :opening_balance_amount => 0, :opening_balance_currency => Constants::Money::DEFAULT_CURRENCY, :opening_balance_effect => Constants::Accounting::CREDIT_EFFECT, :accounts_chart => @accounts_chart)
    @test_liability_account.saved?.should be_true

    @test_income_account = Ledger.create(:accounts_chart => @accounts_chart, :name => "Test income account #{DateTime.now}", :account_type => Constants::Accounting::INCOMES, :open_on => @open_date, :opening_balance_amount => 0, :opening_balance_currency => Constants::Money::DEFAULT_CURRENCY, :opening_balance_effect => Constants::Accounting::CREDIT_EFFECT, :accounts_chart => @accounts_chart)
    @test_income_account.saved?.should be_true

    @test_expense_account = Ledger.create(:accounts_chart => @accounts_chart, :name => "Test expense account #{DateTime.now}", :account_type => Constants::Accounting::EXPENSES, :open_on => @open_date, :opening_balance_amount => 0, :opening_balance_currency => Constants::Money::DEFAULT_CURRENCY, :opening_balance_effect => Constants::Accounting::DEBIT_EFFECT, :accounts_chart => @accounts_chart)
    @test_expense_account.saved?.should be_true
  end

  it "the balance on a ledger for a particular cost center is the cumulative effect of postings to the ledger from vouchers that have that cost center" do
  end

end
