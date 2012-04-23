require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe DateValidator do

  it "should screen a set of dates such that it drops dates that are on or later than the 'before' date" do
    test_date_strs = [ '2012-01-03', '2012-01-08', '2012-01-11', '2012-01-25', '2012-02-12', '2012-02-13' ]
    test_dates = test_date_strs.collect {|date_str| Date.parse(date_str)}
    
    on_or_after_date = Date.parse('2012-01-01'); before_date = Date.parse('2012-02-12')
    screened_dates = DateValidator.screen_dates(test_dates, on_or_after_date, before_date)

    test_dates.delete_if { |date| [Date.parse('2012-02-12'), Date.parse('2012-02-13')].include?(date) }
    screened_dates.should == test_dates
  end

  it "should screen a set of dates such that it drops dates that are earlier than the 'on_or_after' date" do
    test_date_strs = [ '2012-01-03', '2012-01-08', '2012-01-11', '2012-01-25', '2012-02-12', '2012-02-13' ]
    test_dates = test_date_strs.collect {|date_str| Date.parse(date_str)}

    on_or_after_date = Date.parse('2012-01-10'); before_date = Date.parse('2012-02-20')
    screened_dates = DateValidator.screen_dates(test_dates, on_or_after_date, before_date)

    test_dates.delete_if { |date| [Date.parse('2012-01-03'), Date.parse('2012-01-08')].include?(date) }
    screened_dates.should == test_dates
  end

  it "should screen a set of dates such that it only retains dates that are on_or_after until dates that are before" do
    test_date_strs = [ '2012-01-03', '2012-01-08', '2012-01-11', '2012-01-25', '2012-02-12', '2012-02-13' ]
    test_dates = test_date_strs.collect {|date_str| Date.parse(date_str)}

    on_or_after_date = Date.parse('2012-01-08'); before_date = Date.parse('2012-02-13')
    screened_dates = DateValidator.screen_dates(test_dates, on_or_after_date, before_date)

    test_dates.delete_if { |date| [Date.parse('2012-01-03'), Date.parse('2012-02-13')].include?(date)}
    screened_dates.should == test_dates
  end

  it "should sort the returned date range in chronological order" do
    test_date_strs = [ '2012-01-03', '2012-01-08', '2012-01-11', '2012-01-25', '2012-02-12', '2012-02-13' ]
    test_dates = test_date_strs.collect {|date_str| Date.parse(date_str)}
    test_dates = test_dates.reverse

    on_or_after_date = Date.parse('2012-01-08'); before_date = Date.parse('2012-02-13')
    screened_dates = DateValidator.screen_dates(test_dates, on_or_after_date, before_date)

    test_dates.delete_if { |date| [Date.parse('2012-01-03'), Date.parse('2012-02-13')].include?(date)}
    screened_dates.should == test_dates.sort
  end

end
