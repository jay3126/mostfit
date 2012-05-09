require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe CostCenter do

  before(:each) do
    @cost_center = Factory(:cost_center)
  end

  it "it should not be valid without a name" do
    @cost_center.name = nil
    @cost_center.should_not be_valid
  end

  it "should sort cost centers on the cost center name" do
    sorted_names = FACTORY_NAMES.sort
  	cost_centers = FACTORY_NAMES.collect {|naam| CostCenter.new(:name => naam)}
  	sorted_cost_centers = cost_centers.sort
  	0.upto(sorted_cost_centers.length - 1) { |idx|
      sorted_cost_centers[idx].name.should == sorted_names[idx]
    }
  end

end