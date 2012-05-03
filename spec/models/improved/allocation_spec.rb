require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

class ProRataImpl
  include Allocation::ProRata
end

class EarliestInterestThenEarliestPrincipalImpl
  include Allocation::EarliestInterestThenEarliestPrincipal
end

class InterestFirstThenPrincipalImpl
  include Allocation::InterestFirstThenPrincipal
end

describe Allocation do

  it "should add up principal and interest amounts for installments as expected" do
    due_amounts = {
      1 => {:principal => 400, :interest => 100},
      2 => {:principal => 400, :interest => 100},
      3 => {:principal => 400, :interest => 100},
      4 => {:principal => 400, :interest => 100}
    }
    total_interest = 400; total_principal = 1600
    allocation_impl = ProRataImpl.new
    principal_and_interest = allocation_impl.total_principal_and_interest(due_amounts)
    principal_and_interest[:principal].should == total_principal
    principal_and_interest[:interest].should == total_interest

    due_amounts = {
      1 => {:principal => 390, :interest => 110},
      2 => {:principal => 395, :interest => 105},
      3 => {:principal => 405, :interest => 95},
      4 => {:principal => 410, :interest => 90}
    }
    total_interest = 400; total_principal = 1600
    principal_and_interest = allocation_impl.total_principal_and_interest(due_amounts)
    principal_and_interest[:principal].should == total_principal
    principal_and_interest[:interest].should == total_interest
  end

  it "should allocate amounts prorata when the amount to be allocated is less than the due amounts" do
    amount = 1000
    against_due_amounts = {
      1 => {:principal => 400, :interest => 100},
      2 => {:principal => 400, :interest => 100},
      3 => {:principal => 400, :interest => 100},
      4 => {:principal => 400, :interest => 100}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => 800, :interest => 200, :amount_not_allocated => 0}
    pro_rata_impl = ProRataImpl.new
    allocation = pro_rata_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = 1200
    against_due_amounts = {
      1 => {:principal => 400, :interest => 100},
      2 => {:principal => 400, :interest => 100},
      3 => {:principal => 400, :interest => 100},
      4 => {:principal => 400, :interest => 100}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => 960, :interest => 240, :amount_not_allocated => 0}
    allocation = pro_rata_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = 1200
    against_due_amounts = {
      1 => {:principal => 390, :interest => 110},
      2 => {:principal => 395, :interest => 105},
      3 => {:principal => 405, :interest => 95},
      4 => {:principal => 410, :interest => 90}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => 960, :interest => 240, :amount_not_allocated => 0}
    allocation = pro_rata_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation
  end

  it "should allocate amounts prorata when the amount to be allocated is more than the due amounts" do
    amount = 2200
    against_due_amounts = {
      1 => {:principal => 390, :interest => 110},
      2 => {:principal => 395, :interest => 105},
      3 => {:principal => 405, :interest => 95},
      4 => {:principal => 410, :interest => 90}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => 1600, :interest => 400, :amount_not_allocated => 200}
    pro_rata_impl = ProRataImpl.new
    allocation = pro_rata_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation
  end

  it "should allocate amounts earliest interest first, then earliest principal
first, when the amount is less than the due amounts" do
    amount = 1000
    against_due_amounts = {
      1 => {:principal => 400, :interest => 100},
      2 => {:principal => 400, :interest => 100},
      3 => {:principal => 400, :interest => 100},
      4 => {:principal => 400, :interest => 100}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => 800, :interest => 200, :amount_not_allocated => 0}
    eitep = EarliestInterestThenEarliestPrincipalImpl.new
    allocation = eitep.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = 300
    against_due_amounts = {
      1 => {:principal => 390, :interest => 110},
      2 => {:principal => 395, :interest => 105},
      3 => {:principal => 405, :interest => 95},
      4 => {:principal => 410, :interest => 90}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => 190, :interest => 110, :amount_not_allocated => 0}
    allocation = eitep.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = 100
    against_due_amounts = {
      1 => {:principal => 390, :interest => 110},
      2 => {:principal => 395, :interest => 105},
      3 => {:principal => 405, :interest => 95},
      4 => {:principal => 410, :interest => 90}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => 0, :interest => 100, :amount_not_allocated => 0}
    allocation = eitep.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = 200
    against_due_amounts = {
      1 => {:principal => 390, :interest => 110},
      2 => {:principal => 395, :interest => 105},
      3 => {:principal => 405, :interest => 95},
      4 => {:principal => 410, :interest => 90}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => 90, :interest => 110, :amount_not_allocated => 0}
    allocation = eitep.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = 700
    against_due_amounts = {
      1 => {:principal => 390, :interest => 110},
      2 => {:principal => 395, :interest => 105},
      3 => {:principal => 405, :interest => 95},
      4 => {:principal => 410, :interest => 90}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => (390 + 95), :interest => (110 + 105), :amount_not_allocated => 0}
    allocation = eitep.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = 1200
    against_due_amounts = {
      1 => {:principal => 390, :interest => 110},
      2 => {:principal => 395, :interest => 105},
      3 => {:principal => 405, :interest => 95},
      4 => {:principal => 410, :interest => 90}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => (390 + 395 + 105), :interest => (110 + 105 + 95), :amount_not_allocated => 0}
    allocation = eitep.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation
  end

  it "should allocate amounts earliest interest first, then earliest principal
first, when the amount to be allocated is more than the due amounts" do
    amount = 2000
    against_due_amounts = {
      1 => {:principal => 400, :interest => 100},
      2 => {:principal => 400, :interest => 100},
      3 => {:principal => 400, :interest => 100},
      4 => {:principal => 400, :interest => 100}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => 1600, :interest => 400, :amount_not_allocated => 0}
    eitep = EarliestInterestThenEarliestPrincipalImpl.new
    allocation = eitep.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = 2300
    against_due_amounts = {
      1 => {:principal => 400, :interest => 100},
      2 => {:principal => 400, :interest => 100},
      3 => {:principal => 400, :interest => 100},
      4 => {:principal => 400, :interest => 100}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => 1600, :interest => 400, :amount_not_allocated => 300}
    allocation = eitep.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation
  end

  it "should allocate amounts interest first, then principal first,
  when the amount is less than the due amounts" do
    amount = 1000
    against_due_amounts = {
      1 => {:principal => 400, :interest => 100},
      2 => {:principal => 400, :interest => 100},
      3 => {:principal => 400, :interest => 100},
      4 => {:principal => 400, :interest => 100}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => 600, :interest => 400, :amount_not_allocated => 0}
    interest_first = InterestFirstThenPrincipalImpl.new
    allocation = interest_first.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = 1200
    against_due_amounts = {
      1 => {:principal => 390, :interest => 110},
      2 => {:principal => 395, :interest => 105},
      3 => {:principal => 405, :interest => 95},
      4 => {:principal => 410, :interest => 90}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => 800, :interest => 400, :amount_not_allocated => 0}
    allocation = interest_first.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = 300
    against_due_amounts = {
      1 => {:principal => 390, :interest => 110},
      2 => {:principal => 395, :interest => 105},
      3 => {:principal => 405, :interest => 95},
      4 => {:principal => 410, :interest => 90}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => 0, :interest => 300, :amount_not_allocated => 0}
    allocation = interest_first.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation
  end

    it "should allocate all interest and principal,
  when the amount is more than the due amounts for interest first then principal allocation" do
    amount = 2300
    against_due_amounts = {
      1 => {:principal => 390, :interest => 110},
      2 => {:principal => 395, :interest => 105},
      3 => {:principal => 405, :interest => 95},
      4 => {:principal => 410, :interest => 90}
    }
    total_interest = 400; total_principal = 1600
    expected_allocation = {:principal => 1600, :interest => 400, :amount_not_allocated => 300}
    interest_first = InterestFirstThenPrincipalImpl.new
    allocation = interest_first.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation
  end


end