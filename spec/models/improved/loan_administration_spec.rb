require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LoanAdministration do

  before(:each) do
    #loans
    @loan_one = Factory(:lending)

    #centers
    @center_one = Factory(:biz_location)

    @center_two = BizLocation.new
    @center_two.name = Factory.next(:name)
    @center_two.location_level = @center_one.location_level
    @center_two.save
    @center_two.saved?.should be_true

    @center_three = BizLocation.new
    @center_three.name = Factory.next(:name)
    @center_three.location_level = @center_one.location_level
    @center_three.save
    @center_three.saved?.should be_true

    #branches
    @branch_location_one = Factory(:biz_location)

    @branch_location_two = BizLocation.new
    @branch_location_two.name = Factory.next(:name)
    @branch_location_two.location_level = @branch_location_one.location_level
    @branch_location_two.creation_date = @branch_location_one.creation_date
    @branch_location_two.save
    @branch_location_two.saved?.should be_true

    @performed_by = 23; @recorded_by = 71
    @date_one = Date.parse('2012-03-01')
  end

  context "when created" do

    it "should create a loan administration assignment as expected" do
      loan_admin = LoanAdministration.assign(@center_one, @branch_location_one, @loan_one, @performed_by, @recorded_by, @date_one)
      loan_admin.saved?.should be_true

      loan_admin.administered_at_location.should == @center_one
      loan_admin.accounted_at_location.should == @branch_location_one
      loan_admin.to_location_map.should == {Constants::Loan::ADMINISTERED_AT => @center_one, Constants::Loan::ACCOUNTED_AT => @branch_location_one}

    end

    it "should retrieve the administrated and accounted locations for the loan as expected" do
      loan_admin = LoanAdministration.assign(@center_one, @branch_location_one, @loan_one, @performed_by, @recorded_by, @date_one)
      loan_admin.saved?.should be_true

      LoanAdministration.get_administered_at(@loan_one.id, (@date_one - 1)).should be_nil
      LoanAdministration.get_administered_at(@loan_one.id, @date_one).should == @center_one

      LoanAdministration.get_accounted_at(@loan_one.id, (@date_one - 1)).should be_nil
      LoanAdministration.get_accounted_at(@loan_one.id, @date_one).should == @branch_location_one
    end

    it "should only allow a single assignment of administered and accounted at locations on a loan on any given date" do
      center_x = BizLocation.new
      center_x.name = Factory.next(:name)
      center_x.location_level = @center_one.location_level
      center_x.save
      center_x.saved?.should be_true

      d0 = Date.parse('2012-03-01')

      LoanAdministration.assign(@center_one, @branch_location_one, @loan_one, @performed_by, @recorded_by, d0)
      lambda {LoanAdministration.assign(@center_one, @branch_location_one, @loan_one, @performed_by, @recorded_by, d0)}.should raise_error
      lambda {LoanAdministration.assign(center_x, @branch_location_one, @loan_one, @performed_by, @recorded_by, d0)}.should raise_error
    end

    it "should return the correct list of loans administered (or accounted) at a location in the event of re-assignment" do
      #loans
      loan_attributes = @loan_one.attributes
      loan_attributes.delete(:id)
      @loan_two = Lending.new(loan_attributes)
      @loan_two.lan = "2 #{DateTime.now}"
      @loan_two.save
      @loan_two.saved?.should be_true

      @loan_three = Lending.new(loan_attributes)
      @loan_three.lan = "3 #{DateTime.now}"
      @loan_three.save
      @loan_three.saved?.should be_true

      d0 = Date.parse('2012-03-01')
      d1 = d0 + 3

      LoanAdministration.assign(@center_one, @branch_location_one, @loan_one, @performed_by, @recorded_by, d0)
      LoanAdministration.assign(@center_one, @branch_location_one, @loan_two, @performed_by, @recorded_by, d0)
      LoanAdministration.assign(@center_two, @branch_location_one, @loan_three, @performed_by, @recorded_by, d0)

      LoanAdministration.assign(@center_one, @branch_location_two, @loan_one, @performed_by, @recorded_by, d1)

      administered_d0_c1 = []

      (d0...d1).each { |on_date|
        accounted_d0_b1 = LoanAdministration.get_loans_accounted(@branch_location_one.id, on_date)
        accounted_d0_b1.length.should == 3
        accounted_d0_b1.include?(@loan_one).should == true
        accounted_d0_b1.include?(@loan_two).should == true
        accounted_d0_b1.include?(@loan_three).should == true

        administered_d0_c1 = LoanAdministration.get_loans_administered(@center_one.id, on_date)
        administered_d0_c1.length.should == 2
        administered_d0_c1.include?(@loan_one).should == true
        administered_d0_c1.include?(@loan_two).should == true

        administered_d0_c2 = LoanAdministration.get_loans_administered(@center_two.id, on_date)
        administered_d0_c2.length.should == 1
        administered_d0_c2.include?(@loan_three).should == true
      }

      accounted_d1_b2 = LoanAdministration.get_loans_accounted(@branch_location_two.id, (d1 + 1))
      accounted_d1_b2.length.should == 1
      accounted_d1_b2.include?(@loan_one).should == true

      administered_d1_c1 = LoanAdministration.get_loans_administered(@center_one.id, d1)
      (administered_d1_c1.sort).should == (administered_d0_c1.sort)

    end

    it "should accurately retrieve the administrated and accounted locations for the loan after a change in assignment" do

      d0 = Date.parse('2012-03-01')
      d1 = d0 + 3
      d2 = d1 + 5
      d3 = d2 + 7

      LoanAdministration.assign(@center_one, @branch_location_one, @loan_one, @performed_by, @recorded_by, d1)
      LoanAdministration.assign(@center_one, @branch_location_two, @loan_one, @performed_by, @recorded_by, d2)

      (d0..d3).each { |on_date|
        administered_at = LoanAdministration.get_administered_at(@loan_one.id, on_date)
        accounted_at = LoanAdministration.get_accounted_at(@loan_one.id, on_date)

        if ((d0 <= on_date) and (on_date < d1))
          administered_at.should be_nil
          accounted_at.should be_nil
          next
        end

        if (((d1 <= on_date) and (on_date < d2)))
          administered_at.should == @center_one
          accounted_at.should == @branch_location_one
          next
        end

        if ((d2 <= on_date) and (on_date <= d3))
          administered_at.should == @center_one
          accounted_at.should == @branch_location_two
          next
        end
      }

    end

  end

end