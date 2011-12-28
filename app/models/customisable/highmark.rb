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
      debugger
      unless response_text.blank?
        r = JSON::parse(response_text)
        if true # TODO make this check the various parameters from the response and mark status appropriately
          self.status = :accepted
        else
          self.status = :rejected
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
          debugger
          hr.save
        end
        
        def to_highmark_xml
        end
      end
    end

  end


 
end
