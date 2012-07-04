require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe SimpleFeeProduct do

  before(:each) do
    @loan_product = Factory(:lending_product)
    @insurance_product = Factory(:simple_insurance_product)
    @default_currency = MoneyManager.get_default_currency

    common_timed_amount_attributes = Factory.attributes_for(:timed_amount)

    @effective_date_april = Date.parse('2012-04-01')
    @effective_date_may = Date.parse('2012-05-01')

    @april_fee_amount = Money.new(10100, @default_currency); @april_tax_amount = Money.new(1100, @default_currency)
    @may_fee_amount = Money.new(9900, @default_currency); @may_tax_amount = Money.new(670, @default_currency)

    amount_april_attributes = common_timed_amount_attributes.merge(:fee_only_amount => @april_fee_amount.amount, :tax_only_amount => @april_tax_amount.amount, :effective_on => @effective_date_april)
    @amount_april = Factory.create(:timed_amount, amount_april_attributes)

    amount_may_attributes = common_timed_amount_attributes.merge(:fee_only_amount => @may_fee_amount.amount, :tax_only_amount => @may_tax_amount.amount, :effective_on => @effective_date_may)
    @amount_may = Factory.create(:timed_amount, amount_may_attributes)

    common_fee_attributes = Factory.attributes_for(:simple_fee_product)
    loan_fee_attributes = common_fee_attributes.merge(:name => "loan fee", :lending_product_for_fee => @loan_product)
    @loan_fee = Factory.create(:simple_fee_product, loan_fee_attributes)
    @loan_fee.timed_amounts << @amount_april << @amount_may
    @loan_fee.save

    penalty_fee_attributes = common_fee_attributes.merge(:name => "penalty", :lending_product_for_penalty => @loan_product)
    @penalty_fee = Factory.create(:simple_fee_product, penalty_fee_attributes)
    @penalty_fee.timed_amounts << @amount_april << @amount_may
    @penalty_fee.save

    insurance_premium_attributes = common_fee_attributes.merge(:name => "premium", :simple_insurance_product => @insurance_product)
    @insurance_premium = Factory.create(:simple_fee_product, insurance_premium_attributes)
    @insurance_premium.timed_amounts << @amount_april << @amount_may
    @insurance_premium.save
  end

  it "should report the effective fee amount, tax amount, and total amounts as expected per the effective date" do
    april_date = Date.parse('2012-04-15')
    may_date = Date.parse('2012-05-15')
debugger
    @loan_fee.effective_fee_only_amount((@effective_date_april - 1)).should be_nil
    @loan_fee.effective_tax_only_amount((@effective_date_april - 1)).should be_nil

    @loan_fee.effective_fee_only_amount(april_date).should == @april_fee_amount
    @loan_fee.effective_tax_only_amount(april_date).should == @april_tax_amount
    @loan_fee.effective_total_amount(april_date).should == (@april_fee_amount + @april_tax_amount)

    @loan_fee.effective_fee_only_amount(may_date).should == @may_fee_amount
    @loan_fee.effective_tax_only_amount(may_date).should == @may_tax_amount
    @loan_fee.effective_total_amount(may_date).should == (@may_fee_amount + @may_tax_amount)
  end

  it "should report the applicable loan fees and preclosure penalty fees on a loan product as expected" do
    @loan_product.loan_fee = @loan_fee
    @loan_product.save

    applicable_fee_products = SimpleFeeProduct.get_applicable_fee_products_on_loan_product(@loan_product.id)
    applicable_fee_products[Constants::Transaction::FEE_CHARGED_ON_LOAN].should == @loan_fee

    @loan_product.loan_preclosure_penalty = @penalty_fee
    @loan_product.save

    applicable_fee_products = SimpleFeeProduct.get_applicable_fee_products_on_loan_product(@loan_product.id)
    applicable_fee_products[Constants::Transaction::FEE_CHARGED_ON_LOAN].should == @loan_fee
    applicable_fee_products[Constants::Transaction::PRECLOSURE_PENALTY_ON_LOAN].should == @penalty_fee
  end

  it "should report the applicable premium on an insurance product as expected" do
    @insurance_product.premium = @insurance_premium
    @insurance_product.save
    SimpleFeeProduct.get_applicable_premium_on_insurance_product(@insurance_product.id)[Constants::Transaction::PREMIUM_COLLECTED_ON_INSURANCE].should == @insurance_premium
  end

  it "should report the total fees including applicable loan fees, preclosure penalty fees,
and applicable premium on a loan product that has attached insurance product
as expected" do
    @loan_product.loan_fee = @loan_fee
    @loan_product.loan_preclosure_penalty = @penalty_fee

    @insurance_product.premium = @insurance_premium
    @insurance_product.save

    @loan_product.simple_insurance_products << @insurance_product
    @loan_product.save
  end
  
end
