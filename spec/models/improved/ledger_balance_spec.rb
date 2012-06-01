require File.join( File.dirname(__FILE__), '..', '..', 'spec_helper')

describe LedgerBalance do

  before(:all) do
    @zero_inr_debit_balance = LedgerBalance.zero_debit_balance(:INR)
    @debit_inr_balance_one = LedgerBalance.new(100, :INR, :debit)
    @debit_inr_balance_two = LedgerBalance.new(40, :INR, :debit)
    @debit_inr_balances = [@zero_inr_debit_balance, @debit_inr_balance_one, @debit_inr_balance_two]

    @zero_inr_credit_balance = LedgerBalance.zero_credit_balance(:INR)
    @credit_inr_balance_one = LedgerBalance.new(100, :INR, :credit)
    @credit_inr_balance_two = LedgerBalance.new(60, :INR, :credit)
    @credit_inr_balances = [@zero_inr_credit_balance, @credit_inr_balance_one, @credit_inr_balance_two]
    @all_inr_balances = [@debit_inr_balances, @credit_inr_balances].flatten
    
    @zero_usd_credit_balance = LedgerBalance.zero_credit_balance(:USD)
    @credit_usd_balance_one = LedgerBalance.new(100, :USD, :credit)
    @zero_usd_debit_balance = LedgerBalance.zero_debit_balance(:USD)
    @debit_usd_balance_one = LedgerBalance.new(30, :USD, :debit)
    @all_usd_balances = [@zero_usd_credit_balance, @credit_usd_balance_one, @zero_usd_debit_balance, @debit_usd_balance_one]
    @all_balances = [@all_usd_balances, @all_inr_balances].flatten    
  end

  it "should raise an error if constructed with a nil amount, or nil currency, or nil effect" do
    lambda { LedgerBalance.new(nil, :INR, :debit) }.should raise_error
    lambda { LedgerBalance.new(100, nil, :debit) }.should raise_error
    lambda { LedgerBalance.new(100, :INR, nil) }.should raise_error
    lambda { LedgerBalance.new(nil, nil, nil) }.should raise_error
  end

  it "should raise an error if constructed with a negative amount" do
    lambda { LedgerBalance.new(-100, :INR, :debit) }.should raise_error
  end

  it "should raise an error if constructed with a currency that is not currently configured" do
    lambda { LedgerBalance.new(100, :sestertii, :debit) }.should raise_error
  end

  it "should raise an error if constructed with an invalid accounting effect" do
    lambda { LedgerBalance.new(100, :INR, :dr) }.should raise_error
  end

  it "should return a balance amount as constructed" do
    @all_inr_balances.each do |bal|
      [bal.amount, bal.currency, bal.effect].should == bal.balance
    end
  end
  
  it "zero balance should have zero amount" do
    zero_balance = LedgerBalance.zero_balance(:INR, :debit)
    zero_balance.amount.should == 0
  end

  it "zero debit balance should have zero amount and debit effect" do
    zero_debit_balance = LedgerBalance.zero_debit_balance(:INR)
    zero_debit_balance.amount.should == 0
    zero_debit_balance.effect.should == :debit
  end
  
  it "zero credit balance should have zero amount and credit effect" do
    zero_credit_balance = LedgerBalance.zero_credit_balance(:INR)
    zero_credit_balance.amount.should == 0
    zero_credit_balance.effect.should == :credit
  end

  it "a balance with debit effect should be reported as a debit balance, else nil" do
    @debit_inr_balances.each { |bal|
      bal.is_debit_balance?.should == true
      bal.get_debit_balance.should == bal
      bal.get_debit_balance.should_not == nil
    }

    @credit_inr_balances.each { |bal|
      bal.is_debit_balance?.should == false
      bal.get_debit_balance.should == nil
      bal.get_debit_balance.should_not == bal
    }
  end

  it "a balance with credit effect should be reported as a credit balance, else nil" do
    @credit_inr_balances.each { |bal|
      bal.is_credit_balance?.should == true
      bal.get_credit_balance.should == bal
      bal.get_credit_balance.should_not == nil
    }

    @debit_inr_balances.each { |bal|
      bal.is_credit_balance?.should == false
      bal.get_credit_balance.should == nil
      bal.get_credit_balance.should_not == bal
    }
  end
  
  it "a valid balance object should be valid" do
    @all_inr_balances.each do |bal|
      LedgerBalance.valid_balance_obj?(bal).should == true
    end
  end
  
  it "a list of balance objects that are all valid should be valid when validated together" do
    LedgerBalance.validate_balances(*@all_balances).should == true
  end
  
  it "a list of balances that are all the same currency can be added together" do
    LedgerBalance.can_add_balances?(*@all_inr_balances).should == true
    LedgerBalance.can_add_balances?(*@all_usd_balances).should == true
  end
  
  it "a list of balances that are in different currencies can not be added together" do
    LedgerBalance.can_add_balances?(*@all_balances).first.should == false
  end
  
  it "adding a zero balance, whether credit or debit to another balance should leave the other balanace unchanged" do
    @all_inr_balances.each do |bal|
      amount, currency, effect = bal.amount, bal.currency, bal.effect
      add_zero_credit_balance = bal + @zero_inr_credit_balance
      add_zero_credit_balance.amount.should == amount
      add_zero_credit_balance.currency.should == currency
      add_zero_credit_balance.effect.should == effect
      
      add_zero_debit_balance = bal + @zero_inr_debit_balance
      add_zero_debit_balance.amount.should == amount
      add_zero_debit_balance.currency.should == currency
      add_zero_debit_balance.effect.should == effect
    end
    
    @all_usd_balances.each do |bal|
      amount, currency, effect = bal.amount, bal.currency, bal.effect
      add_zero_credit_balance = bal + @zero_usd_debit_balance
      add_zero_credit_balance.amount.should == amount
      add_zero_credit_balance.currency.should == currency
      add_zero_credit_balance.effect.should == effect
      
      add_zero_debit_balance = bal + @zero_usd_debit_balance
      add_zero_debit_balance.amount.should == amount
      add_zero_debit_balance.currency.should == currency
      add_zero_debit_balance.effect.should == effect
    end
  end
  
  it "balances of the same effect add together arithmetically" do
    debit_zero = LedgerBalance.zero_debit_balance(:INR)
    debit_twenty = LedgerBalance.new(20, :INR, :debit)
    debit_thirty = LedgerBalance.new(30, :INR, :debit)
    
    zero_plus_twenty = debit_zero + debit_twenty
    zero_plus_twenty.amount.should == 20
    zero_plus_twenty.effect.should == :debit
    
    zero_plus_thirty = debit_zero + debit_thirty
    zero_plus_thirty.amount.should == 30
    zero_plus_thirty.effect.should == :debit
    
    twenty_plus_thirty = debit_twenty + debit_thirty
    twenty_plus_thirty.amount.should == 50
    twenty_plus_thirty.effect.should == :debit
  end
  
  it "balances of different effect add together as their difference with the effect of the larger balance" do
    debit_twenty = LedgerBalance.new(20, :INR, :debit)
    debit_thirty = LedgerBalance.new(30, :INR, :debit)
    credit_fifteen = LedgerBalance.new(15, :INR, :credit)
    credit_twenty_five = LedgerBalance.new(25, :INR, :credit)
    
    sum_one = debit_twenty + credit_fifteen
    sum_one.amount.should == 5
    sum_one.effect.should == :debit
    sum_one.currency.should == :INR
    
    sum_two = debit_twenty + credit_twenty_five
    sum_two.amount.should == 5
    sum_two.effect.should == :credit
    sum_two.currency.should == :INR
    
    sum_three = debit_thirty + credit_fifteen
    sum_three.amount.should == 15
    sum_three.effect.should == :debit
    sum_three.currency.should == :INR
    
    sum_four = debit_thirty + credit_twenty_five
    sum_four.amount.should == 5
    sum_four.effect.should == :debit
    sum_four.currency.should == :INR
  end
  
  it "addition of balances is associative" do
    debit_zero = LedgerBalance.zero_debit_balance(:INR)
    debit_twenty = LedgerBalance.new(20, :INR, :debit)
    debit_thirty = LedgerBalance.new(30, :INR, :debit)
    
    zero_plus_twenty = debit_zero + debit_twenty
    twenty_plus_thirty = debit_twenty + debit_thirty

    zero_plus_twenty_add_thirty = zero_plus_twenty + debit_thirty
    zero_add_twenty_plus_thirty = debit_zero + twenty_plus_thirty
    zero_plus_twenty_add_thirty.should == zero_add_twenty_plus_thirty
  end
  
  it "sum of several balances is the same as the balances added to each other one by one" do
    debit_twenty = LedgerBalance.new(20, :INR, :debit)
    debit_thirty = LedgerBalance.new(30, :INR, :debit)
    credit_fifteen = LedgerBalance.new(15, :INR, :credit)
    credit_twenty_five = LedgerBalance.new(25, :INR, :credit)
    
    LedgerBalance.add_balances(debit_twenty).should == debit_twenty

    sum_one = debit_twenty + debit_thirty
    sum_several_one = LedgerBalance.add_balances(debit_twenty, debit_thirty)
    sum_several_one.should == sum_one

    sum_two = sum_one + credit_fifteen
    sum_several_two = LedgerBalance.add_balances(debit_twenty, debit_thirty, credit_fifteen)
    sum_several_two.should == sum_two
  end
  
  it "balances that do not add up to zero are not balanced" do
    LedgerBalance.are_balanced?(*@debit_inr_balances).should == false    
    LedgerBalance.are_balanced?(*@credit_inr_balances).should == false
    LedgerBalance.are_balanced?(*@all_inr_balances).should == false
    LedgerBalance.are_balanced?(*@all_usd_balances).should == false
  end
  
  it "balances that add up to zero are balanced" do
    debit_twenty = LedgerBalance.new(20, :INR, :debit)
    debit_thirty = LedgerBalance.new(30, :INR, :debit)
    credit_five = LedgerBalance.new(5, :INR, :credit)
    credit_thirty_five = LedgerBalance.new(35, :INR, :credit)
    credit_ten = LedgerBalance.new(10, :INR, :credit)
    
    LedgerBalance.are_balanced?(debit_twenty, debit_thirty, credit_five, credit_thirty_five, credit_ten).should == true
    LedgerBalance.are_balanced?(@zero_inr_debit_balance).should == true
    LedgerBalance.are_balanced?(credit_ten).should == false
    LedgerBalance.are_balanced?(debit_thirty, credit_five, credit_thirty_five, credit_ten).should == false
  end

  it "tests a balance that is a zero balance as expected" do
    zero_debit_balance = LedgerBalance.zero_debit_balance(Constants::Money::DEFAULT_CURRENCY)
    LedgerBalance.is_zero_balance?(zero_debit_balance).should be_true

    zero_credit_balance = LedgerBalance.zero_credit_balance(Constants::Money::DEFAULT_CURRENCY)
    LedgerBalance.is_zero_balance?(zero_credit_balance).should be_true

    debit_ten = LedgerBalance.new(10, :INR, :debit)
    LedgerBalance.is_zero_balance?(debit_ten).should be_false
  end
 
end
