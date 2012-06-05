require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe Resolver do

  before(:all) do
    @loan = Factory(:lending)
    @client = Factory(:client)
  end

  it "should fetch product instance as expected" do
    loan_type = Constants::Products::LENDING
    loan_id   = @loan.id
    Resolver.fetch_product_instance(loan_type, loan_id).should == @loan
  end

  it "should fetch counterparty as expected" do
    counterparty_type = Constants::Transaction::CLIENT
    counterparty_id   = @client.id
    Resolver.fetch_counterparty(counterparty_type, counterparty_id).should == @client
  end

  it "should verify counterparty instances as expected" do
    Constants::Transaction::COUNTERPARTIES_AND_MODELS.values.each { |klass_name|
      klass = Kernel.const_get(klass_name)
      obj = klass.new
      Resolver.is_a_counterparty?(obj).should be_true
    }

    class FooClass; def initialize; end; end
    foo_obj = FooClass.new
    Resolver.is_a_counterparty?(foo_obj).should be_false
  end

  it "should resolve counterparty as expected" do
    counterparty = Client.new
    resolution   = Resolver.resolve_counterparty(counterparty)
    resolution.first.should == Constants::Transaction::CLIENT
    resolution.last.should == counterparty.id
  end

end