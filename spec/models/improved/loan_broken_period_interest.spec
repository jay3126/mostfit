require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe Lending do

  before(:all) do
    @weekly_frequency = MarkerInterfaces::Recurrence::WEEKLY
    @biweekly_frequency = MarkerInterfaces::Recurrence::BIWEEKLY

    @ios_begin_weekly = Money.new(24900, :INR)
    @ios_end_weekly   = Money.new(20000, :INR)

    @this_month_and_next_date_strs_weekly = {
      ['2012-05-25', '2012-06-01'] => Money.new(4200, :INR),
      ['2012-05-26', '2012-06-02'] => Money.new(3500, :INR),
      ['2012-05-27', '2012-06-03'] => Money.new(2800, :INR),
      ['2012-05-28', '2012-06-04'] => Money.new(2100, :INR),
      ['2012-05-29', '2012-06-05'] => Money.new(1400, :INR),
      ['2012-05-30', '2012-06-06'] => Money.new(700, :INR)
    }

    @this_month_and_next_dates_weekly = {}
    @this_month_and_next_date_strs_weekly.each { |date_str_ary, amount|
      date_ary = date_str_ary.collect {|date_str| Date.parse(date_str)}
      @this_month_and_next_dates_weekly[date_ary] = amount
    }

    @ios_begin_biweekly = Money.new(214000, :INR)
    @ios_end_biweekly   = Money.new(200000, :INR)

    @this_month_and_next_date_strs_biweekly = {
      ['2012-05-18', '2012-06-01'] => Money.new(13000, :INR),
      ['2012-05-19', '2012-06-02'] => Money.new(12000, :INR),
      ['2012-05-20', '2012-06-03'] => Money.new(11000, :INR),
      ['2012-05-21', '2012-06-04'] => Money.new(10000, :INR),
      ['2012-05-22', '2012-06-05'] => Money.new( 9000, :INR),
      ['2012-05-23', '2012-06-06'] => Money.new( 8000, :INR)
    }

    @this_month_and_next_dates_biweekly = {}
    @this_month_and_next_date_strs_biweekly.each { |date_str_ary, amount|
      date_ary = date_str_ary.collect {|date_str| Date.parse(date_str)}
      @this_month_and_next_dates_biweekly[date_ary] = amount
    }

  end

  it "should calculate the broken period interest as expected for weekly intervals" do
    @this_month_and_next_dates_weekly.each { |dates, amount|
      Allocation::Common.calculate_broken_period_interest(@ios_begin_weekly, @ios_end_weekly, dates.first, dates.last, Date.parse('2012-05-31'), @weekly_frequency).should == amount
    }
  end

  it "should calculate the broken period interest as expected for biweekly intervals" do
    @this_month_and_next_dates_biweekly.each { |dates, amount|
      Allocation::Common.calculate_broken_period_interest(@ios_begin_biweekly, @ios_end_biweekly, dates.first, dates.last, Date.parse('2012-05-31'), @biweekly_frequency).should == amount
    }
  end

end
