require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe Money do

  before(:all) do
    @supported_currencies = Constants::MoneyConstants::CURRENCIES
    @default_currency = Constants::MoneyConstants::DEFAULT_CURRENCY
    @currency_multipliers = Constants::MoneyConstants::CURRENCIES_LEAST_UNITS_MULTIPLIERS
    @ikkis = Money.new(21, @default_currency)
    @ek_sau_ek = Money.new(101, @default_currency)
    @INR = Constants::MoneyConstants::INR
    @USD = Constants::MoneyConstants::USD
    @YEN = Constants::MoneyConstants::YEN
  end

  it "should not accept a currency that is not supported" do
    fictional_currency = :sestertii
    @supported_currencies.include?(fictional_currency).should == false
    lambda { Money.new(101, fictional_currency) }.should raise_error
  end

  it "should not accept an amount that is not an integer" do
    amount = 21.666
    lambda { Money.new(amount, @default_currency) }.should raise_error
  end

  it "should not accept an amount that is negative" do
    red_amount = -21
    lambda { Money.new(red_amount, @default_currency) }.should raise_error
  end

  it "should create instances of money with the specified amount and currency when constructed" do
    a1 = 100;
    m1 = Money.new(a1, @default_currency)
    m1.amount.should == a1
    m1.currency.should == @default_currency
  end

  it "money instances with the same amount and the same currency should be equal" do
    m1 = Money.new(101, @default_currency)
    m1.should == @ek_sau_ek
  end

  it "money instances with a different amount and the same currency are not equal" do
    @ikkis.should_not == @ek_sau_ek
  end

  it "money instances with the same amount but different currencies are not equal" do
    tenner = Money.new(1000, @USD)
    dussi = Money.new(1000, @INR)
    tenner.should_not == dussi
    dussi.should_not == tenner
  end

  it "money instances with both different amounts and different currencies are not equal" do
    tenner = Money.new(1000, @USD)
    tenner.should_not == @ikkis
  end

  it "should format the amount for Indian Rupees with the correct decimal places as per the multiplier" do
    amount_in_paise = 7103
    m1 = Money.new(amount_in_paise, @INR)
    m1.to_s.should == "71.03 INR"
  end

  it "should format the amount for Japanese Yen without decimal separators" do
    amount_in_yen = 2351
    m1 = Money.new(amount_in_yen, @YEN)
    m1.to_s.should == amount_in_yen.to_s + " JPY"
  end

  it "should convert the regular amount to an amount in least units by dividing the same by the multiplier for a currency with hundreds in least terms" do
    locale = nil
    amount_in_rupees_str = "73.125"
    money = Money.parse(@INR, locale, amount_in_rupees_str)
    money.amount.should == 7312

    amount_in_rupees_str = "73.19"
    money = Money.parse(@INR, locale, amount_in_rupees_str)
    money.amount.should == 7319

    amount_in_rupees_str = "73"
    money = Money.parse(@INR, locale, amount_in_rupees_str)
    money.amount.should == 7300

    amount_in_rupees_str = "73.00"
    money = Money.parse(@INR, locale, amount_in_rupees_str)
    money.amount.should == 7300

    amount_in_rupees_str = "73.3"
    money = Money.parse(@INR, locale, amount_in_rupees_str)
    money.amount.should == 7330

    amount_in_rupees_str = "73.07"
    money = Money.parse(@INR, locale, amount_in_rupees_str)
    money.amount.should == 7307
  end

  it "should convert the regular amount to an amount in least units by dividing the same by the multiplier for a currency that is always in least terms" do
    locale = nil
    amount_in_yen_str = "73125"
    money = Money.parse(@YEN, locale, amount_in_yen_str)
    money.amount.should == 73125
  end

  it "should refuse to add when not given money" do
    lambda { @ikkis + 101 }.should raise_error
  end

  it "should refuse to add money amounts that are not the same currency" do
    tenner = Money.new(1000, @USD)
    lambda {tenner + @ikkis}.should raise_error(ArgumentError)
  end

  it "should add amounts arithmetically for money" do
    (@ikkis + @ek_sau_ek).amount.should == (21 + 101)
    (@ek_sau_ek + @ikkis).amount.should == (21 + 101)
  end

  it "should subtract one money amount from the other by taking the difference of the amounts" do
    (@ikkis - @ek_sau_ek).amount.should == (101 - 21)
    (@ek_sau_ek - @ikkis).should == (@ikkis - @ek_sau_ek)
  end

  it "should return a money amount of zero value when requested for the particular currency" do
    zero_usd = Money.zero_money_amount(@USD)
    zero_usd.amount.should == 0; zero_usd.currency.should == @USD
  end

end