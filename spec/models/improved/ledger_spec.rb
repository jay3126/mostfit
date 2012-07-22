require File.join( File.dirname(__FILE__), '..', '..', 'spec_helper')

describe Ledger do

  before(:each) do
    @accounts_chart = Factory(:accounts_chart)

    ledger_attributes = Factory.attributes_for(:ledger)
    @open_on= Date.parse('2012-04-01')
    @default_currency = MoneyManager.get_default_currency

    @cash_opening_balance_money_amount = Money.new(101, @default_currency)
    @cash = Factory.create(:ledger, ledger_attributes.merge(:name => "Cash", :account_type => Constants::Accounting::ASSETS, :open_on => @open_on, :opening_balance_amount => @cash_opening_balance_money_amount.amount, :opening_balance_currency => @cash_opening_balance_money_amount.currency, :opening_balance_effect => Constants::Accounting::DEBIT_EFFECT))

    @loans_taken_opening_balance_money_amount  = Money.new(101, @default_currency)
    @loans_taken = Factory.create(:ledger, ledger_attributes.merge(:name => "Loans taken", :account_type => Constants::Accounting::LIABILITIES, :open_on => @open_on, :opening_balance_amount => @loans_taken_opening_balance_money_amount.amount, :opening_balance_currency => @loans_taken_opening_balance_money_amount.currency, :opening_balance_effect => Constants::Accounting::CREDIT_EFFECT))

    @loans_made_opening_balance_money_amount   = MoneyManager.default_zero_money
    @loans_made = Factory.create(:ledger, ledger_attributes.merge(:name => "Loans made", :account_type => Constants::Accounting::ASSETS, :open_on => @open_on, :opening_balance_amount => @loans_made_opening_balance_money_amount.amount, :opening_balance_currency => @loans_made_opening_balance_money_amount.currency, :opening_balance_effect => Constants::Accounting::DEBIT_EFFECT))
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
    opening_balance, open_on = @cash.opening_balance_and_date
    opening_balance.amount.should == @cash_opening_balance_money_amount.amount
    opening_balance.currency.should == @cash_opening_balance_money_amount.currency
    opening_balance.effect.should == Constants::Accounting::DEBIT_EFFECT
    open_on.should == @open_on
  end

  it "the balance on a ledger as of a given point in time is the cumulative effect of the postings to the ledger until that point in time (combined with the opening balance)" do
    date_one = @open_on + 31

    voucher_one_money_amount = Money.new(21, @default_currency)
    cash_payment_voucher_one = Voucher.new(:total_amount => voucher_one_money_amount.amount, :currency => voucher_one_money_amount.currency, :effective_on => date_one, :generated_mode => Constants::Accounting::MANUAL_VOUCHER)
    cash_credit_one = LedgerPosting.new(:voucher => cash_payment_voucher_one, :ledger => @cash, :effective_on => date_one, :amount => voucher_one_money_amount.amount, :currency => voucher_one_money_amount.currency, :effect => Constants::Accounting::CREDIT_EFFECT)
    loans_made_debit_one = LedgerPosting.new(:voucher => cash_payment_voucher_one, :ledger => @loans_made, :effective_on => date_one, :amount => voucher_one_money_amount.amount, :currency => voucher_one_money_amount.currency, :effect => Constants::Accounting::DEBIT_EFFECT)
    cash_payment_voucher_one.ledger_postings.push(cash_credit_one)
    cash_payment_voucher_one.ledger_postings.push(loans_made_debit_one)
    cash_payment_voucher_one.save.should be_true

    #balances on ledgers
    cash_opening_balance = @cash.opening_balance_and_date.first
    loans_made_opening_balance = @loans_made.opening_balance_and_date.first
    @cash.balance(date_one - 1).should == cash_opening_balance
    @loans_made.balance(date_one - 1).should == loans_made_opening_balance

    @cash.balance(date_one).should == (cash_credit_one.to_balance + cash_opening_balance)
    @loans_made.balance(date_one).should == (loans_made_debit_one.to_balance + loans_made_opening_balance)
  end

end
