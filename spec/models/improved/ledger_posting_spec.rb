require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LedgerPosting do

  before(:all) do
    @voucher = Voucher.new(:total_amount => 100, :effective_on => Date.today)
    @accounts_chart = Factory(:accounts_chart)
  end

  before(:each) do 
    @cash = Ledger.new(:accounts_chart => @accounts_chart, :name => "Cash", :account_type => Constants::Accounting::ASSETS, :open_on => Date.today, :opening_balance_amount => 0, :opening_balance_currency => :INR, :opening_balance_effect => Constants::Accounting::DEBIT_EFFECT)
    @cash.should be_valid

    @loans_made = Ledger.new(:accounts_chart => @accounts_chart, :name => "Loans made", :account_type => Constants::Accounting::ASSETS, :open_on => Date.today, :opening_balance_amount => 0, :opening_balance_currency => :INR, :opening_balance_effect => Constants::Accounting::DEBIT_EFFECT)
    @loans_made.should be_valid

    @credit_posting = LedgerPosting.new(:voucher => @voucher, :ledger => @cash, :amount => 100, :effect => Constants::Accounting::CREDIT_EFFECT, :effective_on => @voucher.effective_on)
    @debit_posting = LedgerPosting.new(:voucher => @voucher, :ledger => @loans_made, :amount => 100, :effect => Constants::Accounting::DEBIT_EFFECT, :effective_on => @voucher.effective_on)
  end

  it "should not be valid without an effective_on date" do
    @credit_posting.effective_on = nil
    @credit_posting.should_not be_valid  
  end

  it "should not be valid without a posting amount" do
    @credit_posting.amount = nil
    @credit_posting.should_not be_valid
  end

  it "should not be valid if the posting amount is zero" do
    @credit_posting.amount = 0
    @credit_posting.should_not be_valid
  end
  
  it "should not be valid without a posting currency" do
    @credit_posting.currency = nil
    @credit_posting.should_not be_valid
  end
  
  it "should not be valid without a posting effect" do
    @credit_posting.effect = nil
    @credit_posting.should_not be_valid
  end
  
  it "should not be valid without a valid accounting impact" do
    posting_amount, posting_currency, posting_effect = @credit_posting.amount, @credit_posting.currency, @credit_posting.effect
    @credit_posting.amount = -100
    @credit_posting.should_not be_valid
    @credit_posting.amount = posting_amount
    
    @credit_posting.currency = :sestertii
    @credit_posting.should_not be_valid
    @credit_posting.currency = posting_currency
    
    @credit_posting.effect = :dr
    @credit_posting.should_not be_valid
    @credit_posting.effect = posting_effect
  end

  it "should not be valid without a voucher" do
    @credit_posting.voucher = nil
    @credit_posting.should_not be_valid
  end
  
  it "should not be valid without a ledger" do
    @credit_posting.ledger = nil
    @credit_posting.should_not be_valid
  end

end
