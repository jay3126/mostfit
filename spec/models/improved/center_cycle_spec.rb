require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe CenterCycle do

  before(:each) do
    @center = Factory(:center)
    @by_staff_id = 23
    @initiated_on_date = Date.today
    @created_by = 12
  end

  it "first cycle for the center should have cycle number one" do
    current_cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    current_cycle_number.should == 0
    first_cycle = CenterCycle.new(
      :center_id => @center.id,
      :initiated_by_staff_id => @by_staff_id,
      :initiated_on => @initiated_on_date,
      :cycle_number => (current_cycle_number + 1),
      :status => Constants::Space::OPEN_CENTER_CYCLE_STATUS,
      :created_by => @created_by
    )
    first_cycle.should be_valid
    @center.center_cycles << first_cycle
    @center.save
    CenterCycle.get_current_center_cycle(@center.id).should == 1
  end

  it "should not be valid unless initiated precedes closed when closed" do
    current_cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    current_cycle_number.should == 0
    first_cycle = CenterCycle.new(
      :center_id => @center.id,
      :initiated_by_staff_id => @by_staff_id,
      :initiated_on => @initiated_on_date,
      :cycle_number => (current_cycle_number + 1),
      :status => Constants::Space::OPEN_CENTER_CYCLE_STATUS,
      :created_by => @created_by
    )
    first_cycle.should be_valid
    @center.center_cycles << first_cycle
    @center.save

    lambda{first_cycle.mark_cycle_closed(@by_staff_id, @initiated_on_date - 1)}.should raise_error
    
    first_cycle.mark_cycle_closed(@by_staff_id, @initiated_on_date + 1)
    first_cycle.get_cycle_status.should == Constants::Space::CLOSED_CENTER_CYCLE_STATUS
  end

  it "a new cycle added for a center must have the next successive cycle number" do
    current_cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    current_cycle_number.should == 0
    first_cycle = CenterCycle.new(
      :center_id => @center.id,
      :initiated_by_staff_id => @by_staff_id,
      :initiated_on => @initiated_on_date,
      :cycle_number => (current_cycle_number + 1),
      :status => Constants::Space::OPEN_CENTER_CYCLE_STATUS,
      :created_by => @created_by
    )
    first_cycle.should be_valid
    @center.center_cycles << first_cycle
    @center.save

    cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    cycle_number.should == 1

    second_cycle = CenterCycle.new(
      :center_id => @center.id,
      :initiated_by_staff_id => @by_staff_id,
      :initiated_on => @initiated_on_date,
      :cycle_number => (cycle_number + 1),
      :status => Constants::Space::OPEN_CENTER_CYCLE_STATUS,
      :created_by => @created_by
    )
    second_cycle.should be_valid
    second_cycle.save

    next_cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    next_cycle_number.should == 2

    invalid_cycle = CenterCycle.new(
      :center_id => @center.id,
      :initiated_by_staff_id => @by_staff_id,
      :initiated_on => @initiated_on_date,
      :status => Constants::Space::OPEN_CENTER_CYCLE_STATUS,
      :created_by => @created_by
    )
    invalid_cycle.cycle_number = next_cycle_number + 2
    invalid_cycle.should_not be_valid

    invalid_cycle.cycle_number = next_cycle_number + 3
    invalid_cycle.should_not be_valid

    invalid_cycle.cycle_number = next_cycle_number - 1
    invalid_cycle.should_not be_valid

    invalid_cycle.cycle_number = next_cycle_number + 1
    invalid_cycle.should be_valid
    invalid_cycle.save
    CenterCycle.get_current_center_cycle(@center.id).should == 3
  end

  it "the status is set to closed when a center cycle is marked closed" do
    current_cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    current_cycle_number.should == 0
    first_cycle = CenterCycle.new(
      :center_id => @center.id,
      :initiated_by_staff_id => @by_staff_id,
      :initiated_on => @initiated_on_date,
      :cycle_number => (current_cycle_number + 1),
      :status => Constants::Space::OPEN_CENTER_CYCLE_STATUS,
      :created_by => @created_by
    )
    first_cycle.should be_valid
    @center.center_cycles << first_cycle
    @center.save

    first_cycle = @center.center_cycles.first
    first_cycle.mark_cycle_closed(@by_staff_id, @initiated_on_date + 1)
    first_cycle.get_cycle_status.should == Constants::Space::CLOSED_CENTER_CYCLE_STATUS
  end

end