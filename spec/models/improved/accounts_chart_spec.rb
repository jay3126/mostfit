require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe AccountsChart do

  before(:each) do
    @test_accounts_chart = Factory(:accounts_chart)
  end

  it "should not be valid without a name" do
    @test_accounts_chart.name = nil
    @test_accounts_chart.should_not be_valid
  end

  it "should have a unique name to be valid" do
    another_chart = AccountsChart.new(:name => @test_accounts_chart.name, :chart_type => Constants::Accounting::FINANCIAL_ACCOUNTING)
    another_chart.should_not be_valid
  end

end