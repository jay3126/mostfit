require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe PaymentTransaction do

  before(:each) do
    @amount = 10000
    @currency = Constants::Money::INR
    @money_amount = Money.new(@amount, @currency)
    @receipt_type = Constants::Transaction::RECEIPT
    @on_product_type = Constants::Products::LENDING
    @on_product_id = 12
    @by_counterparty_type = Constants::Transaction::CLIENT
    @by_counterparty_id = 13
    @performed_at = 14
    @accounted_at = 15
    @performed_by = 7
    @recorded_by = 9
    @effective_on = Date.parse('2012-05-01')

    @receipt = PaymentTransaction.new(
      :amount               => @amount,
      :currency             => @currency,
      :receipt_type         => @receipt_type,
      :on_product_type      => @on_product_type,
      :on_product_id        => @on_product_id,
      :by_counterparty_type => @by_counterparty_type,
      :by_counterparty_id   => @by_counterparty_id,
      :performed_at         => @performed_at,
      :accounted_at         => @accounted_at,
      :performed_by         => @performed_by,
      :recorded_by          => @recorded_by,
      :effective_on         => @effective_on
    )
  end

  it "should disallow a future-dated transaction" do 
    @receipt.effective_on = (Date.today + 1)
    @receipt.should_not be_valid
   
    @receipt.effective_on = (Date.today - 1)
    @receipt.should be_valid
  end

  it "should record a payment as expected" do
    payment = PaymentTransaction.record_payment(@money_amount, @receipt_type, @on_product_type, @on_product_id, @by_counterparty_type, @by_counterparty_id, @performed_at, @accounted_at, @performed_by, @effective_on, @recorded_by)
    payment.saved?.should be_true
    payment.amount.should == @money_amount.amount
    payment.currency.should == @money_amount.currency
    payment.receipt_type.should == @receipt_type
    payment.on_product_type.should == @on_product_type
    payment.on_product_id.should == @on_product_id
    payment.by_counterparty_type.should == @by_counterparty_type
    payment.by_counterparty_id.should == @by_counterparty_id
    payment.performed_at.should == @performed_at
    payment.accounted_at.should == @accounted_at
    payment.performed_by.should == @performed_by
    payment.effective_on.should == @effective_on
    payment.recorded_by.should == @recorded_by
  end

  it "should not be valid without specifying whether it is a payment or a receipt" do
    @receipt.receipt_type = nil
    @receipt.should_not be_valid
  end

  it "should not be valid without having a product type" do
    @receipt.on_product_type = nil
    @receipt.should_not be_valid
  end

  it "should not be valid without having a product ID" do
    @receipt.on_product_id = nil
    @receipt.should_not be_valid
  end

  it "should not be valid without specifying the customer type the payment is being accepted for" do
    @receipt.by_counterparty_type = nil
    @receipt.should_not be_valid
  end

  it "should not be valid without specifying the customer ID the payment is being accepted for" do
    @receipt.by_counterparty_id = nil
    @receipt.should_not be_valid
  end

  it "should not be valid without specifying a valid amount" do
    @receipt.amount = nil
    @receipt.should_not be_valid
  end

  it "should not be valid without specifying a valid currency" do
    @receipt.currency = nil
    @receipt.should_not be_valid
  end

  it "should not be valid without specifying the staff that collected the payment" do
    @receipt.performed_by = nil
    @receipt.should_not be_valid
  end

  it "should not be valid without specifying a value date" do
    @receipt.effective_on = nil
    @receipt.should_not be_valid
  end

  it "should not be valid without specifying a location that the payment was performed at" do
    @receipt.performed_at = nil
    @receipt.should_not be_valid
  end

  it "should not be valid without specifying a location that the payment was accounted at" do
    @receipt.accounted_at = nil
    @receipt.should_not be_valid
  end

  it "should not be valid without specifying the user that recorded the payment" do
    @receipt.recorded_by = nil
    @receipt.should_not be_valid
  end

end
