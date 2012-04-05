require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

class OverlapReportInterpreterImpl
  include OverlapReportInterpreter
  
  attr_reader :applied_for_amount, :no_of_active_loans, :total_outstanding

  def initialize(applied_for_amount, no_of_active_loans, total_outstanding)
    @applied_for_amount = applied_for_amount
    @no_of_active_loans = no_of_active_loans
    @total_outstanding = total_outstanding
  end

end

describe OverlapReportInterpreterImpl do

  it "should rate the report as positive if the number of loans allowed does not exceed the configured value" do
    total_outstanding_allowed = ConfigurationFacade.instance.regulation_total_oustanding_allowed
    applied_for_amount = 10000
    total_outstanding = total_outstanding_allowed - applied_for_amount - 5000

    @report_one = OverlapReportInterpreterImpl.new(applied_for_amount, 1, total_outstanding)
    @report_one.rate_report.should == Constants::CreditBureau::RATED_POSITIVE
  end

  it "should rate the report as positive if the total outstanding exceeds configured value"

  it "should rate the report as positive if the number of loans allowed does not exceed configured value and the total outstanding does not exceed 50000"

  it "should rate the report as negative if number of loans allowed exceeds configured value"

  it "should rate the report as negative if total outstanding exceeds configured value"

end