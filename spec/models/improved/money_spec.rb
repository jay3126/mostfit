require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe Money do

  before(:all) do
    @supported_currencies = Constants::Money::CURRENCIES
    @default_currency = Constants::Money::DEFAULT_CURRENCY
    @currency_multipliers = Constants::Money::CURRENCIES_LEAST_UNITS_MULTIPLIERS
    @gyarah = Money.new(11, @default_currency)
    @ikkis = Money.new(21, @default_currency)
    @ikyavan = Money.new(51, @default_currency)
    @ek_sau_ek = Money.new(101, @default_currency)
    @INR = Constants::Money::INR
    @USD = Constants::Money::USD
    @YEN = Constants::Money::YEN
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

    amount_in_paise = 103
    m1 = Money.new(amount_in_paise, @INR)
    m1.to_s.should == "1.03 INR"

    amount_in_paise = 23
    Money.new(amount_in_paise, @INR).to_s.should == "0.23 INR"

    amount_in_paise = 7
    Money.new(amount_in_paise, @INR).to_s.should == "0.07 INR"

    amount_in_paise = 0
    Money.new(amount_in_paise, @INR).to_s.should == "0.00 INR"
  end

  it "should format the amount for Japanese Yen without decimal separators" do
    amount_in_yen = 2351
    m1 = Money.new(amount_in_yen, @YEN)
    m1.to_s.should == amount_in_yen.to_s + " JPY"

    amount_in_yen = 351
    Money.new(amount_in_yen, @YEN).to_s.should == "351 JPY"

    amount_in_yen = 51
    Money.new(amount_in_yen, @YEN).to_s.should == "51 JPY"

    amount_in_yen = 1
    Money.new(amount_in_yen, @YEN).to_s.should == "1 JPY"
  end

  it "should multiply a money amount as expected" do
    tenner = Money.new(1000, :INR)
    (tenner * 12).should == Money.new((1000 * 12), :INR)

    (tenner * 0.12).should == Money.new((1000 * 0.12).to_i, :INR)
    #TODO must be enhanced for the multiplication of fractional amounts and for division
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

  it "given a hash of money amounts, the from_money method should return a hash with just amounts and a currency" do
    principal_amount = 2000; interest_amount = 1000
    currency = Constants::Money::DEFAULT_CURRENCY
    money_amounts_hash = {:principal_amount => Money.new(principal_amount, currency), :interest_amount => Money.new(interest_amount, currency)}
    result_hash = Money.from_money(money_amounts_hash)
    result_hash[:principal_amount].should == principal_amount
    result_hash[:interest_amount].should == interest_amount
    result_hash[:currency].should == currency
    result_hash.keys.length.should == 3
  end

  it "money is compared by amount when in the same currency" do
    (@ikkis < @ek_sau_ek).should be_true
    (@ikkis > @gyarah).should be_true
    [@ek_sau_ek, @gyarah, @ikkis, @ikyavan].sort.should == [@gyarah, @ikkis, @ikyavan, @ek_sau_ek]

    quid = Money.new(20, :USD)
    lambda { @ikkis < quid }.should raise_error
  end

  it "produces a hash of money amounts given a hash of numeric amounts as expected" do
    money_amounts_hash = {:foo => 10000, :bar => 1200}
    money_hash = Money.money_amounts_hash_to_money(money_amounts_hash, :INR)
    money_hash[:foo].should == Money.new(10000, :INR)
    money_hash[:bar].should == Money.new(1200, :INR)
    money_hash.keys.length.should == 2
  end


end