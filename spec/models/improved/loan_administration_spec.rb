require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LoanAdministration do

  before(:each) do
    @center_location = Factory(:biz_location)

    @branch_location_one = Factory(:biz_location)
    @branch_location_two = BizLocation.new
    @branch_location_two.name = Factory.next(:name)
    @branch_location_two.location_level = @branch_location_one.location_level
    @branch_location_two.creation_date = @branch_location_one.creation_date
    @branch_location_two.save
    @branch_location_two.saved?.should be_true

    @lending = Factory(:lending)

    @performed_by = 23; @recorded_by = 71

    @date_one = Date.parse('2012-03-01')
  end

  context "when created" do

    it "should create a loan administration assignment as expected" do
      loan_admin = LoanAdministration.assign(@center_location, @branch_location_one, @lending, @performed_by, @recorded_by, @date_one)
      loan_admin.saved?.should be_true

      loan_admin.administered_at_location.should == @center_location
      loan_admin.accounted_at_location.should == @branch_location_one
      loan_admin.to_location_map.should == {Constants::Loan::ADMINISTERED_AT_LOCATION => @center_location, Constants::Loan::ACCOUNTED_AT_LOCATION => @branch_location_one}

    end

    it "should retrieve the administrated and accounted locations for the loan as expected" do
      loan_admin = LoanAdministration.assign(@center_location, @branch_location_one, @lending, @performed_by, @recorded_by, @date_one)
      loan_admin.saved?.should be_true

      LoanAdministration.get_administered_at(@lending.id, (@date_one - 1)).should be_nil
      LoanAdministration.get_administered_at(@lending.id, @date_one).should == @center_location

      LoanAdministration.get_accounted_at(@lending.id, (@date_one - 1)).should be_nil
      LoanAdministration.get_accounted_at(@lending.id, @date_one).should == @branch_location_one
    end

    it "should accurately retrieve the administrated and accounted locations for the loan after a change in assignment" do

      d0 = Date.parse('2012-03-01')
      d1 = d0 + 3
      d2 = d1 + 5
      d3 = d2 + 7

      LoanAdministration.assign(@center_location, @branch_location_one, @lending, @performed_by, @recorded_by, d1)
      LoanAdministration.assign(@center_location, @branch_location_two, @lending, @performed_by, @recorded_by, d2)

      (d0..d3).each { |on_date|
        administered_at = LoanAdministration.get_administered_at(@lending.id, on_date)
        accounted_at = LoanAdministration.get_accounted_at(@lending.id, on_date)

        if ((d0 <= on_date) and (on_date < d1))
          administered_at.should be_nil
          accounted_at.should be_nil
          next
        end

        if (((d1 <= on_date) and (on_date < d2)))
          administered_at.should == @center_location
          accounted_at.should == @branch_location_one
          next
        end

        if ((d2 <= on_date) and (on_date <= d3))
          administered_at.should == @center_location
          accounted_at.should == @branch_location_two
          next
        end
      }

    end

  end

end