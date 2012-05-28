require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe Allocation do

  before(:all) do
    @spd = Constants::LoanAmounts::SCHEDULED_PRINCIPAL_DUE
    @spo = Constants::LoanAmounts::SCHEDULED_PRINCIPAL_OUTSTANDING
    @slid = Constants::LoanAmounts::SCHEDULED_INTEREST_DUE
    @slio = Constants::LoanAmounts::SCHEDULED_INTEREST_OUTSTANDING
    @currency = Constants::Money::DEFAULT_CURRENCY
    @pro_rata_impl = Constants::LoanAmounts.get_allocator(Constants::LoanAmounts::PRO_RATA_ALLOCATION, @currency)
    @iftp_impl = Constants::LoanAmounts.get_allocator(Constants::LoanAmounts::INTEREST_FIRST_THEN_PRINCIPAL_ALLOCATION, @currency)
    @eiftep_impl = Constants::LoanAmounts.get_allocator(Constants::LoanAmounts::EARLIEST_INTEREST_FIRST_THEN_EARLIEST_PRINCIPAL_ALLOCATION, @currency)
  end

  it "should convert amortization items to due amounts as expected" do
    third_installment = {
        [3, Date.parse('2012-04-22')] =>
            { @spd => MoneyManager.get_money_instance(171.88), @slid => MoneyManager.get_money_instance(48.12)
            }
    }

    fourth_installment = {
        [4, Date.parse('2012-04-29')] =>
            { @spd => MoneyManager.get_money_instance(172.74), @slid => MoneyManager.get_money_instance(47.26)
            }
    }
    amortization_items = [third_installment, fourth_installment]

    expected_due_amounts = {
        3 => {:principal => MoneyManager.get_money_instance(171.88), :interest => MoneyManager.get_money_instance(48.12)},
        4 => {:principal => MoneyManager.get_money_instance(172.74), :interest => MoneyManager.get_money_instance(47.26)}
    }

    @pro_rata_impl.amortization_to_due_amounts(amortization_items).should == expected_due_amounts
  end

  it "should netoff the allocated amounts as expected" do
    debugger
    first_installment = {
        [1, Date.parse('2012-04-08')] =>
            { @spd => MoneyManager.get_money_instance(170.18), @slid => MoneyManager.get_money_instance(49.82) }
    }
    second_installment = {
        [2, Date.parse('2012-04-15')] =>
            { @spd => MoneyManager.get_money_instance(171.03), @slid => MoneyManager.get_money_instance(48.97) }
    }
    third_installment = {
        [3, Date.parse('2012-04-22')] =>
            { @spd => MoneyManager.get_money_instance(171.88), @slid => MoneyManager.get_money_instance(48.12) }
    }
    fourth_installment = {
        [4, Date.parse('2012-04-29')] =>
            { @spd => MoneyManager.get_money_instance(172.74), @slid => MoneyManager.get_money_instance(47.26) }
    }
    against_due_amounts_val = [first_installment, second_installment, third_installment, fourth_installment]

    allocation = {:principal => MoneyManager.get_money_instance(200.00), :interest => MoneyManager.get_money_instance(80.00)}
    expected_netted_off_amounts = {
      1 => {:principal => MoneyManager.get_money_instance(141.21), :interest => MoneyManager.get_money_instance(18.79)},
      2 => {:principal => MoneyManager.get_money_instance(171.88), :interest => MoneyManager.get_money_instance(48.12)},
      3 => {:principal => MoneyManager.get_money_instance(172.74), :interest => MoneyManager.get_money_instance(47.26)}
    }

    @pro_rata_impl.netoff_allocation(allocation, against_due_amounts_val).should == expected_netted_off_amounts


    allocation = {:principal => MoneyManager.get_money_instance(200.00), :interest => MoneyManager.get_money_instance(98.79)}
    expected_netted_off_amounts = {
        1 => {:principal => MoneyManager.get_money_instance(141.21), :interest => MoneyManager.get_money_instance(0)},
        2 => {:principal => MoneyManager.get_money_instance(171.88), :interest => MoneyManager.get_money_instance(48.12)},
        3 => {:principal => MoneyManager.get_money_instance(172.74), :interest => MoneyManager.get_money_instance(47.26)}
    }

  end

  it "should add up principal and interest amounts for installments as expected" do
    due_amounts = {
      1 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      2 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      3 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      4 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)

    principal_and_interest = @pro_rata_impl.total_principal_and_interest(due_amounts)
    principal_and_interest[:principal].should == total_principal
    principal_and_interest[:interest].should == total_interest

    due_amounts = {
      1 => {:principal => Money.new(390, @currency), :interest => Money.new(110, @currency)},
      2 => {:principal => Money.new(395, @currency), :interest => Money.new(105, @currency)},
      3 => {:principal => Money.new(405, @currency), :interest => Money.new(95, @currency)},
      4 => {:principal => Money.new(410, @currency), :interest => Money.new(90, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    principal_and_interest = @pro_rata_impl.total_principal_and_interest(due_amounts)
    principal_and_interest[:principal].should == total_principal
    principal_and_interest[:interest].should == total_interest
  end

  it "should allocate amounts prorata when the amount to be allocated is less than the due amounts" do
    amount = Money.new(1000, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      2 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      3 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      4 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => Money.new(800, @currency), :interest => Money.new(200, @currency), :amount_not_allocated => Money.new(0, @currency)}
    allocation = @pro_rata_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = Money.new(1200, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      2 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      3 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      4 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => Money.new(960, @currency), :interest => Money.new(240, @currency), :amount_not_allocated => Money.new(0, @currency)}
    allocation = @pro_rata_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = Money.new(1200, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(390, @currency), :interest => Money.new(110, @currency)},
      2 => {:principal => Money.new(395, @currency), :interest => Money.new(105, @currency)},
      3 => {:principal => Money.new(405, @currency), :interest => Money.new(95, @currency)},
      4 => {:principal => Money.new(410, @currency), :interest => Money.new(90, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => Money.new(960, @currency), :interest => Money.new(240, @currency), :amount_not_allocated => Money.new(0, @currency)}
    allocation = @pro_rata_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation
  end

  it "should allocate amounts prorata when the amount to be allocated is more than the due amounts" do
    amount = Money.new(2200, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(390, @currency), :interest => Money.new(110, @currency)},
      2 => {:principal => Money.new(395, @currency), :interest => Money.new(105, @currency)},
      3 => {:principal => Money.new(405, @currency), :interest => Money.new(95, @currency)},
      4 => {:principal => Money.new(410, @currency), :interest => Money.new(90, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => Money.new(1600, @currency), :interest => Money.new(400, @currency), :amount_not_allocated => Money.new(200, @currency)}

    allocation = @pro_rata_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation
  end

  it "should allocate amounts earliest interest first, then earliest principal
first, when the amount is less than the due amounts" do
    amount = Money.new(1000, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      2 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      3 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      4 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => Money.new(800, @currency), :interest => Money.new(200, @currency), :amount_not_allocated => Money.new(0, @currency)}
    allocation = @eiftep_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = Money.new(300, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(390, @currency), :interest => Money.new(110, @currency)},
      2 => {:principal => Money.new(395, @currency), :interest => Money.new(105, @currency)},
      3 => {:principal => Money.new(405, @currency), :interest => Money.new(95, @currency)},
      4 => {:principal => Money.new(410, @currency), :interest => Money.new(90, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => Money.new(190, @currency), :interest => Money.new(110, @currency), :amount_not_allocated => Money.new(0, @currency)}
    allocation = @eiftep_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = Money.new(100, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(390, @currency), :interest => Money.new(110, @currency)},
      2 => {:principal => Money.new(395, @currency), :interest => Money.new(105, @currency)},
      3 => {:principal => Money.new(405, @currency), :interest => Money.new(95, @currency)},
      4 => {:principal => Money.new(410, @currency), :interest => Money.new(90, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => Money.new(0, @currency), :interest => Money.new(100, @currency), :amount_not_allocated => Money.new(0, @currency)}
    allocation = @eiftep_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = Money.new(200, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(390, @currency), :interest => Money.new(110, @currency)},
      2 => {:principal => Money.new(395, @currency), :interest => Money.new(105, @currency)},
      3 => {:principal => Money.new(405, @currency), :interest => Money.new(95, @currency)},
      4 => {:principal => Money.new(410, @currency), :interest => Money.new(90, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => Money.new(90, @currency), :interest => Money.new(110, @currency), :amount_not_allocated => Money.new(0, @currency)}
    allocation = @eiftep_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = Money.new(700, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(390, @currency), :interest => Money.new(110, @currency)},
      2 => {:principal => Money.new(395, @currency), :interest => Money.new(105, @currency)},
      3 => {:principal => Money.new(405, @currency), :interest => Money.new(95, @currency)},
      4 => {:principal => Money.new(410, @currency), :interest => Money.new(90, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => (Money.new(390, @currency) + Money.new(95, @currency)), :interest => (Money.new(110, @currency) + Money.new(105, @currency)), :amount_not_allocated => Money.new(0, @currency)}
    allocation = @eiftep_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = Money.new(1200, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(390, @currency), :interest => Money.new(110, @currency)},
      2 => {:principal => Money.new(395, @currency), :interest => Money.new(105, @currency)},
      3 => {:principal => Money.new(405, @currency), :interest => Money.new(95, @currency)},
      4 => {:principal => Money.new(410, @currency), :interest => Money.new(90, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => Money.new((390 + 395 + 105), @currency), :interest => Money.new((110 + 105 + 95), @currency), :amount_not_allocated => Money.new(0, @currency)}
    allocation = @eiftep_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation
  end

  it "should allocate amounts earliest interest first, then earliest principal
first, when the amount to be allocated is more than the due amounts" do
    amount = Money.new(2000, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      2 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      3 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      4 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => Money.new(1600, @currency), :interest => Money.new(400, @currency), :amount_not_allocated => Money.new(0, @currency)}
    allocation = @eiftep_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = Money.new(2300, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      2 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      3 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      4 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => Money.new(1600, @currency), :interest => Money.new(400, @currency), :amount_not_allocated => Money.new(300, @currency)}
    allocation = @eiftep_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation
  end

  it "should allocate amounts interest first, then principal first,
  when the amount is less than the due amounts" do
    amount = Money.new(1000, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      2 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      3 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)},
      4 => {:principal => Money.new(400, @currency), :interest => Money.new(100, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => Money.new(600, @currency), :interest => Money.new(400, @currency), :amount_not_allocated => Money.new(0, @currency)}
    allocation = @iftp_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = Money.new(1200, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(390, @currency), :interest => Money.new(110, @currency)},
      2 => {:principal => Money.new(395, @currency), :interest => Money.new(105, @currency)},
      3 => {:principal => Money.new(405, @currency), :interest => Money.new(95, @currency)},
      4 => {:principal => Money.new(410, @currency), :interest => Money.new(90, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => Money.new(800, @currency), :interest => Money.new(400, @currency), :amount_not_allocated => Money.new(0, @currency)}
    allocation = @iftp_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation

    amount = Money.new(300, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(390, @currency), :interest => Money.new(110, @currency)},
      2 => {:principal => Money.new(395, @currency), :interest => Money.new(105, @currency)},
      3 => {:principal => Money.new(405, @currency), :interest => Money.new(95, @currency)},
      4 => {:principal => Money.new(410, @currency), :interest => Money.new(90, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => Money.new(0, @currency), :interest => Money.new(300, @currency), :amount_not_allocated => Money.new(0, @currency)}
    allocation = @iftp_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation
  end

    it "should allocate all interest and principal,
  when the amount is more than the due amounts for interest first then principal allocation" do
    amount = Money.new(2300, @currency)
    against_due_amounts = {
      1 => {:principal => Money.new(390, @currency), :interest => Money.new(110, @currency)},
      2 => {:principal => Money.new(395, @currency), :interest => Money.new(105, @currency)},
      3 => {:principal => Money.new(405, @currency), :interest => Money.new(95, @currency)},
      4 => {:principal => Money.new(410, @currency), :interest => Money.new(90, @currency)}
    }
    total_interest = Money.new(400, @currency); total_principal = Money.new(1600, @currency)
    expected_allocation = {:principal => Money.new(1600, @currency), :interest => Money.new(400, @currency), :amount_not_allocated => Money.new(300, @currency)}
    allocation = @iftp_impl.allocate(amount, against_due_amounts)
    allocation.should == expected_allocation
  end


end