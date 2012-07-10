require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe Validators::Arguments do

  it "should raise an error if any argument is nil" do
    foo = 10; bar = "abc"; mel = nil

    lambda {Validators::Arguments.not_nil?(foo)}.should_not raise_error
    lambda {Validators::Arguments.not_nil?(foo, bar)}.should_not raise_error

    lambda {Validators::Arguments.not_nil?(foo, bar, mel)}.should raise_error
    lambda {Validators::Arguments.not_nil?(foo, bar, kut)}.should raise_error
  end

  it "should validate an argument for whether it appears to be an ID as expected" do
    ids = [1, 7, 9, 11, 37]
    ids.each {|id|
      Validators::Arguments.is_id?(id).should be_true
    }

    lambda{ Validators::Arguments.is_id?({}) }.should raise_error
    lambda{ Validators::Arguments.is_id?([]) }.should raise_error
    lambda{ Validators::Arguments.is_id?("some string") }.should raise_error
    lambda{ Validators::Arguments.is_id?(-1) }.should raise_error
    lambda{ Validators::Arguments.is_id?(0) }.should raise_error
    lambda{ Validators::Arguments.is_id?(23.73) }.should raise_error

  end

end

describe Validators::Amounts do

  it "should not raise an error if all arguments are non-negative numbers" do
    foo = 0; bar = 10; mel = 233.45
    lambda { Validators::Amounts.is_positive?(foo, bar, mel) }.should_not raise_error
  end
  
  it "should raise an error if any of the arguments are nil" do
    foo = 10; bar = nil
    lambda {Validators::Amounts.is_positive?(foo, bar)}.should raise_error
  end

  it "should raise an error if any of the arguments are not numbers" do
    foo = 'raju'; bar = 25
    lambda {Validators::Amounts.is_positive?(foo, bar)}.should raise_error
  end

  it "should raise an error if any of the arguments are negative numbers" do
    foo = 600; bar = -2.35
    lambda {Validators::Amounts.is_positive?(foo, bar)}.should raise_error
  end

end
