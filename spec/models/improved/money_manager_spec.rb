require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe MoneyManager do

  it "should return instances of money given a list of money amounts as string for the default currency" do
    amount_strings = %w[ 123.32 122 127.7 191.453 112.06 ]
    amounts_hash = { "123.32" => 12332, "122" => 12200, "127.7" => 12770, "191.453" => 19145, "112.06" => 11206 }
    amounts = MoneyManager.get_money_instance(*amount_strings)
    amount_strings.each_with_index { |amt_str, idx|
      amounts[idx].amount.should == amounts_hash[amt_str] 
      amounts[idx].currency.should == Constants::Money::DEFAULT_CURRENCY
    }
  end

  it "should return an instance of money in the default currency given an amount in least terms" do
    money = MoneyManager.get_money_instance_least_terms(1200)
    money.amount.should == 1200
    money.currency.should == Constants::Money::DEFAULT_CURRENCY
  end

end
