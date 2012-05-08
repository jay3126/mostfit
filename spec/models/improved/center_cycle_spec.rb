require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe CenterCycle do

  before(:all) do
    @center            = Factory(:center)
    @staff_member      = Factory(:staff_member)
    @user              = Factory(:user)
    @initiated_on_date = Date.today
  end

  before(:each) do
    CenterCycle.all.destroy!
    current_cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    current_cycle_number.should == 0
    @center_cycle = CenterCycle.new(
                                    :center_id => @center.id,
                                    :initiated_by_staff_id => @staff_member.id,
                                    :initiated_on => @initiated_on_date,
                                    :cycle_number => (current_cycle_number + 1),
                                    :status => Constants::Space::OPEN_CENTER_CYCLE_STATUS,
                                    :created_by => @user.id
                                    )
    @center_cycle.should be_valid
    @center_cycle.save.should be_true
  end

  it "first cycle for the center should have cycle number one" do
    CenterCycle.get_current_center_cycle(@center.id).should == 1
  end

  it "should not be valid unless initiated precedes closed when closed" do
    first_cycle = @center_cycle
    lambda{first_cycle.mark_cycle_closed(@staff_member.id, @initiated_on_date - 1)}.should raise_error
    
    first_cycle.mark_cycle_closed(@staff_member.id, @initiated_on_date + 1)
    first_cycle.get_cycle_status.should == Constants::Space::CLOSED_CENTER_CYCLE_STATUS
  end

  it "should not be valid unless the previous center cycle has been closed" do
    first_cycle = @center_cycle
    cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    cycle_number.should == 1

    second_cycle = CenterCycle.new(
                                   :center_id => @center.id,
                                   :initiated_by_staff_id => @staff_member.id,
                                   :initiated_on => @initiated_on_date,
                                   :cycle_number => (cycle_number + 1),
                                   :status => Constants::Space::OPEN_CENTER_CYCLE_STATUS,
                                   :created_by => @user.id
                                   )
    second_cycle.should_not be_valid
    
    first_cycle.mark_cycle_closed(@staff_member.id, @initiated_on_date).should be_true
    
    second_cycle.should be_valid
    second_cycle.save.should be_true
  end

  it "should not be valid if the initiated on is before the closed_on of the previous center cycle" do
    first_cycle = @center_cycle
    cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    cycle_number.should == 1
    first_cycle.mark_cycle_closed(@staff_member.id, (@initiated_on_date + 2)).should be_true

    second_cycle = CenterCycle.new(
                                   :center_id => @center.id,
                                   :initiated_by_staff_id => @staff_member.id,
                                   :initiated_on => @initiated_on_date,
                                   :cycle_number => (cycle_number + 1),
                                   :status => Constants::Space::OPEN_CENTER_CYCLE_STATUS,
                                   :created_by => @user.id
                                   )
    second_cycle.should_not be_valid

    second_cycle.initiated_on = @initiated_on_date + 3
    second_cycle.should be_valid
    second_cycle.save.should be_true
  end

  it "a new cycle added for a center must have the next successive cycle number" do
    first_cycle = @center_cycle
    cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    cycle_number.should == 1
    first_cycle.mark_cycle_closed(@staff_member.id, @initiated_on_date).should be_true

    second_cycle = CenterCycle.new(
      :center_id => @center.id,
      :initiated_by_staff_id => @staff_member.id,
      :initiated_on => @initiated_on_date,
      :cycle_number => (cycle_number + 1),
      :status => Constants::Space::OPEN_CENTER_CYCLE_STATUS,
      :created_by => @user.id
    )
    second_cycle.should be_valid
    second_cycle.save

    next_cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    next_cycle_number.should == 2

    second_cycle.mark_cycle_closed(@staff_member.id, @initiated_on_date).should be_true

    invalid_cycle = CenterCycle.new(
      :center_id => @center.id,
      :initiated_by_staff_id => @staff_member.id,
      :initiated_on => @initiated_on_date,
      :status => Constants::Space::OPEN_CENTER_CYCLE_STATUS,
      :created_by => @user.id
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
    first_cycle = @center.center_cycles.first
    first_cycle.mark_cycle_closed(@staff_member.id, @initiated_on_date + 1).should be_true
    first_cycle.get_cycle_status.should == Constants::Space::CLOSED_CENTER_CYCLE_STATUS
  end

end
