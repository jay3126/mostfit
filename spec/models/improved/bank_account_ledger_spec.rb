require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe BankAccountLedger do

  before(:each) do
    @bank = Factory(:bank_account_ledger)
  end

  it "should not be valid if the account type is not ASSETS" do
    other_account_types = Constants::Accounting::ACCOUNT_TYPES - [ Constants::Accounting::ASSETS ]
    other_account_types.each { |type|
      @bank.account_type = type
      @bank.should_not be_valid
    }
    @bank.account_type = Constants::Accounting::ASSETS
    @bank.should be_valid
  end

end