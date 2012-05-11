require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe PaymentTransaction do

  before(:each) do
    amount = 100; currency = Constants::Money::INR
    receipt_type = Constants::Transaction::RECEIPT
    on_product_type = Constants::Transaction::LOAN_PRODUCT
    on_product_id = 12; by_counterparty_type = Constants::Transaction::CLIENT
    by_counterparty_id = 13
    received_at = 14; accounted_at = 15
    performed_by = 7; recorded_by = 9
    effective_on = Date.parse('2012-05-01')

    @receipt = PaymentTransaction.new(
      :amount => amount, :currency => currency,
      :receipt_type => receipt_type,
      :on_product_type => on_product_type, :on_product_id => on_product_id,
      :by_counterparty_type => by_counterparty_type, :by_counterparty_id => by_counterparty_id,
      :performed_at => received_at, :accounted_at => accounted_at,
      :performed_by => performed_by, :recorded_by => recorded_by,
      :effective_on => effective_on
    )
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

  it "should not be valid without specifying the customer type and the customer type the payment is being accepted for" do
    @receipt.by_counterparty_type = nil
    @receipt.should_not be_valid
  end

  it "should not be valid without specifying the customer type and the customer ID the payment is being accepted for" do
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

  it "should not be valid without specifying the user the recorded the payment" do
    @receipt.recorded_by = nil
    @receipt.should_not be_valid
  end

end