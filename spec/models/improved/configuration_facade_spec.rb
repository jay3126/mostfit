require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe ConfigurationFacade do

  before(:all) do
    @configuration = ConfigurationFacade.instance
    @test_week = []
    sunday = Date.parse('2012-03-04'); @test_week << sunday
    1.upto(6).each {|idx| @test_week << (sunday + idx)}
  end

  it "should say that a given date is not a business day, when the weekday is not a business day" do
    @test_week.each { |day|
      day_of_week = Constants::Time.get_week_day(day)
      if @configuration.non_working_days.include?(day_of_week)
        @configuration.is_business_day?(day).should == false
      end
    }
  end

  it "should say that a given date is a business day, when the weekday is a business day" do
    @test_week.each { |day|
      day_of_week = Constants::Time.get_week_day(day)
      if @configuration.business_days.include?(day_of_week)
        @configuration.is_business_day?(day).should == true
      end
    }
  end

end
