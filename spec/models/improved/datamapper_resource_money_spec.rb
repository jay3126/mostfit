require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

class MoneyAmountsModel
  include DataMapper::Resource
  include Constants::Properties

  property :id,                 Serial
  property :foo_money_amount,   *MONEY_AMOUNT
  property :bar_money_amount,   *MONEY_AMOUNT
  property :empty_money_amount, *MONEY_AMOUNT_NULL
  property :currency,           *CURRENCY

  def money_amounts; [:foo_money_amount, :bar_money_amount, :empty_money_amount]; end
end

class NotMoneyAmountModel
  include DataMapper::Resource

  property :id, Serial
  property :name, String
end

describe DataMapper::Resource do

  it "model instance that stores money amounts should return a hash with the amounts when to_money is called" do
    foo_amount = 100; bar_amount = 1200; currency = Constants::Money::DEFAULT_CURRENCY
    money_model_instance = MoneyAmountsModel.new(:foo_money_amount => foo_amount, :bar_money_amount => bar_amount, :currency => currency)

    money_hash = money_model_instance.to_money
    money_hash[:foo_money_amount].amount.should == foo_amount; money_hash[:foo_money_amount].currency.should == currency
    money_hash[:bar_money_amount].amount.should == bar_amount; money_hash[:bar_money_amount].currency.should == currency
    money_hash.keys.length.should == 2

    loan = Factory(:lending)
    loan.to_money.should be_an_instance_of Hash

    lp = Factory(:lending_product)
    lp.to_money.should be_an_instance_of Hash

    lst = Factory(:loan_schedule_template)
    lst.to_money.should be_an_instance_of Hash
  end

  it "model instance that does not store money amounts raises an error when to_money is called" do
    lambda {NotMoneyAmountModel.new.to_money}.should raise_error
  end

  it "returns a money amount for the value of a property when to_money_amount is called" do
    foo_amount = 100; bar_amount = 1200; currency = Constants::Money::DEFAULT_CURRENCY
    money_model_instance = MoneyAmountsModel.new(:foo_money_amount => foo_amount, :bar_money_amount => bar_amount, :currency => currency)

    fm = money_model_instance.to_money_amount(:foo_money_amount)
    fm.currency.should == currency; fm.amount.should == foo_amount
  end

  it "raises an error when to_money_amount is called for a property that is not defined on the instance" do
    foo_amount = 100; bar_amount = 1200; currency = Constants::Money::DEFAULT_CURRENCY
    money_model_instance = MoneyAmountsModel.new(:foo_money_amount => foo_amount, :bar_money_amount => bar_amount, :currency => currency)

    lambda {fm = money_model_instance.to_money_amount(:non_existent_money_amount)}.should raise_error
  end

end
