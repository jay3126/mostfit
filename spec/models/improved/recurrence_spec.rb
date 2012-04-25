require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

class RecurrenceImpl
  include MarkerInterfaces::Recurrence

  attr_reader :frequency
  def initialize(frequency); @frequency = frequency; end

end

describe MarkerInterfaces::Recurrence do

  before(:all) do
    @daily = RecurrenceImpl.new(MarkerInterfaces::Recurrence::DAILY)
    @weekly = RecurrenceImpl.new(MarkerInterfaces::Recurrence::WEEKLY)
    @biweekly = RecurrenceImpl.new(MarkerInterfaces::Recurrence::BIWEEKLY)
    @monthly = RecurrenceImpl.new(MarkerInterfaces::Recurrence::MONTHLY)
  end

  it "all frequencies should accomodate themselves" do
    @daily.can_accomodate?(@daily.frequency).should be_true
    @weekly.can_accomodate?(@weekly.frequency).should be_true
    @biweekly.can_accomodate?(@biweekly.frequency).should be_true
    @monthly.can_accomodate?(@monthly.frequency).should be_true
  end
  
  it "weekly frequency can accomodate biweekly frequency only" do
    @weekly.can_accomodate?(MarkerInterfaces::Recurrence::BIWEEKLY).should be_true

    @weekly.can_accomodate?(MarkerInterfaces::Recurrence::MONTHLY).should be_false
    @biweekly.can_accomodate?(MarkerInterfaces::Recurrence::DAILY).should be_false
  end

  it "daily frequency can accomodate all frequencies greater than a day" do
    MarkerInterfaces::Recurrence::FREQUENCIES.each { |frequency|
      @daily.can_accomodate?(frequency).should be_true
    }
  end

  it "biweekly and monthly frequencies cannot accomodate any other frequency" do
    MarkerInterfaces::Recurrence::FREQUENCIES.each { |frequency|
      next if @biweekly.frequency == frequency
      @biweekly.can_accomodate?(frequency).should be_false
    }

    MarkerInterfaces::Recurrence::FREQUENCIES.each { |frequency|
      next if @monthly.frequency == frequency
      @monthly.can_accomodate?(frequency).should be_false
    }
  end

  it "should return a list of all accomodated frequencies as expected when given a list of frequencies" do
    test_frequencies = [:weekly, :monthly]
    expected_frequencies = MarkerInterfaces::Recurrence.sort_frequencies([:weekly, :monthly, :biweekly])
    MarkerInterfaces::Recurrence.accomodated_frequencies(test_frequencies).should eql expected_frequencies
  end

end
