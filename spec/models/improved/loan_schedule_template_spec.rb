require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LoanScheduleTemplate do  

  context "when created" do

    it "should create a number of schedule line items as expected"

    it "the number of schedule line items must match the number of installments
and one line item for disbursement"

    it "the line items must be numbered serially commencing with
zero for the disbursement and ending with the number of installments"

    it "the line item for disbursement must have principal and interest amounts as expected"

    it "the total of principal and interest amounts due on the line items
must add up to the total principal amount and total interest amounts on the loan"

    it "the currency on individual line items must match the currency on the template schedule"

  end
end
