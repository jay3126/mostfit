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

        def key_person_relationship
          @key_person_relationship ||= {
            :father          => "K01",
            :husband         => "K02",
            :mother          => "K03",
            :son             => "K04",
            :daughter        => "K05",
            :wife            => "K06",
            :brother         => "K07",
            :mother_in_law   => "K08",
            :father_in_law   => "K09",
            :daughter_in_law => "K10",
            :sister_in_law   => "K11",
            :son_in_law      => "K12",
            :brother_in_law  => "K13",
            :other           => "K14"
          }   
        end

        def phone
          @phone ||= {
            :residence => "P01",
            :company   => "P02",
            :mobile    => "P03",
            :permanent => "P04",
            :other     => "P05",
            :untagged  => "P06"
          }
        end

        def id_type
          @id_type ||= {
            "Passport"           => "ID01",
            "Voter ID"           => "ID02",
            "UID"                => "ID03",
            "Others"             => "ID04",
            "Ration Card"        => "ID05",
            "Driving Licence No" => "ID06", 
            "Pan"                => "ID07"
          }
        end
        # creates a row for a loan as per highmarks pipe delimited format 
        def row_to_delimited_file(datetime = DateTime.now)
          client = self.client
          return [
                  "CRDRQINQR",                                                             # segment identifier
                  "JOIN",                                                                  # credit request type
                  "",                                                                      # credit report transaction id
                  "ACCT-ORIG",                                                             # credit inquiry purpose type
                  "",                                                                      # credit inquiry purpose type description
                  "PRE-DISB",                                                              # credit inquiry stage
                  datetime.strftime("%d-%m-%Y %H:%M:%S"),                                  # credit report transaction date time 
                  client.name,                                                             # applicant name 1
                  nil,                                                                     # applicant name 2
                  nil,                                                                     # applicant name 3 
                  nil,                                                                     # applicant name 4
                  nil,                                                                     # applicant name 5 
                  client.next_to_kin_relationship == "Father" ? client.next_to_kin : nil,  # member father name
                  nil,                                                                     # member mother name 
                  client.next_to_kin_relationship == "Husband" ? client.next_to_kin : client.spouse_name, # member spouse name  
                  nil,                                                                     # member relationship type 1 
                  nil,                                                                     # member relationship name 1
                  nil,                                                                     # member relationship type 2
                  nil,                                                                     # member relationship name 2
                  nil,                                                                     # member relationship type 3
                  nil,                                                                     # member relationship name 3
                  nil,                                                                     # member relationship type 4
                  nil,                                                                     # member relationship name 4
                  client.date_of_birth.strftime("%d%m%Y"),                                 # applicant date of birth
                  Date.today.year - client.date_of_birth.year,                             # applicant age
                  Date.today.strftime("%d%m%Y"),                                           # applicant age as of
                  id_type[client.type_of_id],                                                       # applicant id type 1
                  client.reference,                                                        # applicant id 1
                  "ID05",                                                                  # applicant id type 2
                  client.ration_card_number,                                               # applicant id 2
                  self.applied_on,                                                         # account opening date
                  self.id,                                                                 # account id / number
                  client.center.branch.name,                                                      # branch id
                  client.id,                                                               # member id
                  client.center.name,                                               # kendra id
                  self.amount_applied_for,                                                 # applied for amount / current balance
                  nil,                                                                     # key person name
                  nil,                                                                     # key person relationship
                  nil,                                                                     # nominee name
                  nil,                                                                     # nominee relationship
                  client.telephone_type,                                                   # applicant telephone number type 1
                  client.telephone_number,                                                 # applicant telephone number number 1
                  nil,                                                                     # applicant telephone number type 2
                  nil,                                                                     # applicant telephone number number 2
                  "D01",                                                                   # applicant address type 1
                  client.address,                                                          # applicant address 1
                  nil,                                                                     # applicant address 1 city
                  client.state,                                                            # applicant address 1 state
                  client.pincode,                                                          # applicant address 1 pincode
                  nil,                                                                     # applicant address type 2
                  nil,                                                                     # applicant address 2
                  nil,                                                                     # applicant address 2 city
                  nil,                                                                     # applicant address 2 state
                  nil                                                                     # applicant address 2 pincode
                 ]
        end

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
