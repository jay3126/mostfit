require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe AccountsChart do

  before(:each) do
    @test_accounts_chart = Factory(:accounts_chart)
    @counterparty = Factory(:client)
    @counterparty.should be_valid
  end

  it "should not be valid without a name" do
    @test_accounts_chart.name = nil
    @test_accounts_chart.should_not be_valid
  end

  it "should have a unique name to be valid" do
    another_chart = AccountsChart.new(:name => @test_accounts_chart.name, :chart_type => Constants::Accounting::FINANCIAL_ACCOUNTING)
    another_chart.should_not be_valid
  end

  it "should create an acccounts chart for a counterparty as expected and find the same" do
    counterparty_accounts_chart = AccountsChart.setup_counterparty_accounts_chart(@counterparty)
    counterparty_type, counterparty_id = Resolver.resolve_counterparty(@counterparty)

    counterparty_accounts_chart.id.should_not be_nil
    counterparty_accounts_chart.counterparty_type.should == counterparty_type
    counterparty_accounts_chart.counterparty_id.should   == counterparty_id

    AccountsChart.get_counterparty_accounts_chart(@counterparty).should == counterparty_accounts_chart
  end

end