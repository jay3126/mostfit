require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

class ToAssign
  attr_reader :created_on
  def initialize(created_on); @created_on = created_on; end
end

describe Validators::Assignments do

  before(:all) do
    @effective_on = Date.parse('2012-01-01')
    @to_assign_created_same_date = (1..10).each.collect {|num| ToAssign.new(@effective_on)}
    @to_assign_created_later = (1..10).each.collect {|num| ToAssign.new(@effective_on + num)}
    @to_assign_created_earlier = (1..10).each.collect {|num| ToAssign.new(@effective_on - num)}
  end

  it "should allow assignment when the effective date of assignment does not precede the creation date of any of the items assigned" do
    Validators::Assignments.is_valid_assignment_date?(@effective_on,
      *@to_assign_created_earlier).should be_true
  end

  it "should allow assignment when the effective date of assignment is the same as the creation date of the items being assigned" do
    Validators::Assignments.is_valid_assignment_date?(@effective_on,
      *@to_assign_created_same_date).should be_true
  end

  it "should disallow assignment when the effective date of assignment precedes the creation date of all items being assigned" do
    test_val = Validators::Assignments.is_valid_assignment_date?(@effective_on,
      *@to_assign_created_later)
    test_val.should be_an_instance_of(Array)
    test_val.first.should be_false
  end

  it "should disallow assignment when the effective date of assignment precedes the creation date of any item being assigned" do
    test_val = Validators::Assignments.is_valid_assignment_date?(@effective_on,
      @to_assign_created_later.first, @to_assign_created_earlier.first, @to_assign_created_earlier.last)
    test_val.should be_an_instance_of(Array)
    test_val.first.should be_false
  end


end
