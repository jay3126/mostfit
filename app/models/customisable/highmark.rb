module Highmark

  # cleanly inserts all functionality for integration with Highmark Credit Bureau into the application
  # adds properties and methods to Client and Loan 
  # turn this functionality on with an "include Highmark::Client" on the client model. Likewise for Loan model

  class HighmarkResponse
    # parses the response from highmark and attaches it to a loan/client
    # for easy querying
    
    include DataMapper::Resource
    
    property     :id,                  Serial
    property     :created_at,          DateTime
    belongs_to   :created_by,          :child_key => [:created_by_staff_id], :model => StaffMember
    property     :loan_id,             Integer
    property     :client_id,           Integer
    property     :response_text,            Text # Marshal.dump of response hash
    property     :source,              Text # where did this data point come from? typically it comes from
                                            # bulk upload through file or an API request.
                                            # not sure what this property will have right now, but put something appropriate here

    # fields for status
    # pending   -> not done yet
    # failed    -> request attempted. no response recieved
    # success   -> response received, not parsed
    # accepted  -> loan application is ok
    # rejected   -> loan application is not ok
    
    property     :status,              Enum[:pending, :failed, :success, :accepted, :rejected]
    
    belongs_to :loan, :model => ::Loan
    belongs_to :client, :model => ::Client
    
    before :save, :parse_response

    def parse_response
      # this checks the response against the accepted limits and marks the status appropriately
      unless response_text.blank?
        r = JSON::parse(response_text)
        check = nil
        no_of_active_accounts = r["HEADER"]["SUMMARY"]["NO_OF_ACTIVE_ACCOUNTS"].to_i
        no_of_mfis = r["HEADER"]["SUMMARY"]["NO_OF_OTHER_MFIS"].to_i
        responses = [r["RESPONSES"]["RESPONSE"]].flatten
        sum = 0
        responses.each{|x| sum += x["LOAN_DETAILS"]["CURRENT_BAL"].to_f}
        existing_loans_amount = 0
        responses.each{|x| existing_loans_amount += x["LOAN_DETAILS"]["DISBURSED_AMT"].to_f}
        if (no_of_active_accounts >= 2) or ((loan.amount + existing_loans_amount) >= 50000)
          self.status = :rejected          
        else
          self.status = :accepted
        end
      else
        
      end
    end

  end # HighmarkResponse
 
  module Client
    
    # creates a row for a client per highmarks pipe delimited format 
    def row_to_delimited_file(datetime = DateTime.now)
      return ["CRDRQINQR", "JOIN", "", "ACCT-ORIG", "", "PRE-DISB", datetime.strftime("%d-%m-%Y %H:%M:%S"), self.name, self.reference]
    end

    def self.included(base)
      base.class_eval do
        has n, :highmark_responses, :model => Highmark::HighmarkResponse
      end
    end

  end

  module Loan

    def self.included(base)
      base.class_eval do 
        has n, :highmark_responses, :model => Highmark::HighmarkResponse
        after :create, :create_highmark_response

        def create_highmark_response
          hr = HighmarkResponse.new(:loan_id => self.id, :created_by => self.applied_by, :status => :pending, :client_id => self.client.id)
          hr.save
        end
        
        def to_highmark_xml
        end
      end
    end

  end


 
end
