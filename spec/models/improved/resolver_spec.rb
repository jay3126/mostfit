require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe Resolver do

  before(:all) do
    @loan = Factory(:lending)
    @customer = Factory(:customer)
  end

  it "should fetch product instance as expected" do
    debugger
    loan_type = Constants::Products::LENDING
    loan_id = @loan.id
    Resolver.fetch_product_instance(loan_type, loan_id).should == @loan
  end

  it "should fetch counterparty as expected" do
    counterparty_type = Constants::Transaction::CUSTOMER
    counterparty_id = @customer.id
    Resolver.fetch_counterparty(counterparty_type, counterparty_id).should == @customer
  end

end