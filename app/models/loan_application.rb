class LoanApplication
  include DataMapper::Resource
  include Constants::Status
  include Constants::Masters
  include Constants::Space

  property :id,                  Serial
  property :status,              Enum.send('[]', *APPLICATION_STATUSES), :nullable => false, :default => NEW_STATUS
  property :at_branch_id,        Integer, :nullable => false
  property :at_center_id,        Integer, :nullable => false
  property :created_by_staff_id, Integer, :nullable => false
  property :created_by_user_id,  Integer, :nullable => false
  property :created_at,          DateTime, :nullable => false, :default => DateTime.now
  property :created_on,          Date
  property :amount,              Float

  #basic client info
  property :client_id,           Integer, :nullable => true
  property :client_name,         String
  property :client_dob,          Date
  property :client_address,      Text
  property :client_state,        Enum.send('[]', *STATES), :nullable => true
  property :client_pincode,      Integer
  property :client_reference1,   String
  property :client_reference1_type, Enum.send('[]', *REFERENCE_TYPES), :default => 'Others'
  property :client_reference2,   String
  property :client_reference2_type, Enum.send('[]', *REFERENCE_TYPES), :default => 'Others'
  property :client_guarantor_name, String
  property :client_guarantor_relationship, Enum.send('[]', *RELATIONSHIPS), :nullable => true

  has n, :client_verifications
  
  belongs_to :client
  belongs_to :staff_member, :parent_key => [:id], :child_key => [:created_by_staff_id]
  belongs_to :center_cycle

  validates_with_method :created_on, :method => :is_date_within_range?
  validates_with_method :client_id,  :method => :is_unique_for_center_cycle?

  def is_unique_for_center_cycle?
    client_ids = LoanApplication.all(:center_cycle_id => center_cycle_id).aggregate(:client_id)
    return [false, "A loan application for this client #{client_id} already exists for the current loan cycle"] if client_ids.include?(client_id)
    return true
  end

  def is_date_within_range?
    return [false, "cannot be later than today"] if created_on > Date.today
    unless client_id.nil?
      client = Client.get(client_id)
      return [false, "You cannot create a loan application for a client before he has joined"] if created_on < client.date_joined
    end
    return true 
  end

  # Returns the status of loan applications
  def get_status
    self.status
  end

  # Returns true if the loan application is approved, else false
  def is_approved?
    self.get_status == APPROVED_STATUS
  end

  # returns whether a client with the client_id is eligible for a new loan application
  #
  # @param [Integer] the client_id of the client in question
  # @return [Boolean] true/false value that tells whether the client in question is eligible for a new loan application
  def self.allow_new_loan_application?(client_id)
    client = Client.get(client_id)
    raise ArgumentError, "Unable to locate client with ID: #{client_id}" unless client
    client.new_loan_permitted?
  end
  
  # returns the age of the client as calculated from her year of birth
  def client_age
    client_dob.nil? ? nil : (Date.today.year - client_dob.year)
  end

  #tells whether the given Loan Application is pending verification or not
  def is_pending_verification?
    not ClientVerification.is_cpv_complete?(self.id)
  end

  #returns all loan applications which are pending for CPV1 and/or CPV2
  def self.pending_verification(at_branch_id = nil, at_center_id = nil)
    predicates = {}
    if (at_branch_id and !at_branch_id.nil?)
      predicates[:at_branch_id] = at_branch_id
    end
    if (at_center_id and !at_center_id.nil?)
      predicates[:at_center_id] = at_center_id
    end

    all(predicates).select {| l |l.is_pending_verification?}    
  end

  #returns all loan applications for which CPV was recently recorded
  def self.recently_recorded_by_user(by_user_id)
    raise ArgumentError, "User id not supplied" unless by_user_id

    #get all client_verifications which were done by this user
    verifications_by_this_user = ClientVerification.all(:created_by_user_id => by_user_id)

    #get corresponding loan applications
    loan_applications_which_have_CPVs_by_this_user = []
    verifications_by_this_user.each do |v|
        loan_applications_which_have_CPVs_by_this_user.push(LoanApplication.get(v.loan_application_id))
    end
    loan_applications_which_have_CPVs_by_this_user.uniq!

    #get all loan application info objects
    linfos = []
    loan_applications_which_have_CPVs_by_this_user.each do |l|
        puts "Processing #{l}"
        linfos.push(l.to_info)
    end
    linfos
  end

  #returns an object containing all information about a Loan Application
  def to_info
    cpvs_infos = ClientVerification.get_CPVs_infos(self.id)
    puts cpvs_infos
    linfo = LoanApplicationInfo.new(
      self.id,
      self.client_name,
      cpvs_infos['cpv1'],
      cpvs_infos['cpv2'])
    puts linfo
    linfo
  end

  # creates a row for a loan as per highmarks pipe delimited format 
  def row_to_delimited_file(datetime = DateTime.now)
    return [
            "CRDRQINQR",                                                             # segment identifier
            "JOIN",                                                                  # credit request type
            nil,                                                                     # credit report transaction id
            "ACCT-ORIG",                                                             # credit inquiry purpose type
            nil,                                                                     # credit inquiry purpose type description
            "PRE-DISB",                                                              # credit inquiry stage
            datetime.strftime("%d-%m-%Y %H:%M:%S"),                                  # credit report transaction date time 
            client_name,                                                             # applicant name 1
            nil,                                                                     # applicant name 2
            nil,                                                                     # applicant name 3 
            nil,                                                                     # applicant name 4
            nil,                                                                     # applicant name 5 
            nil,  # member father name
            nil,                                                                     # member mother name 
            client_guarantor_name, # member spouse name  
            nil,                                                                     # member relationship type 1 
            nil,                                                                     # member relationship name 1
            nil,                                                                     # member relationship type 2
            nil,                                                                     # member relationship name 2
            nil,                                                                     # member relationship type 3
            nil,                                                                     # member relationship name 3
            nil,                                                                     # member relationship type 4
            nil,                                                                     # member relationship name 4
            client_dob.strftime("%d-%m-%Y"),                                         # applicant date of birth
            client_age,                                                              # applicant age
            Date.today.strftime("%d-%m-%Y"),                                         # applicant age as of
            client_reference2.blank? ? nil : id_type[client_reference2_type],        # applicant id type 1
            client_reference2.blank? ? nil : client_reference2,                      # applicant id 1
            client_reference1.blank? ? nil : "ID05",                                 # applicant id type 2
            client_reference1.blank? ? nil : client_reference1,                      # applicant id 2
            created_on.strftime("%d-%m-%Y"),                                         # account opening date
            id,                                                                      # account id / number
            at_branch_id,                                                            # branch id
            client_id,                                                               # member id
            at_center_id,                                                            # kendra id
            amount,                                                                  # applied for amount / current balance
            client_guarantor_name,                                                   # key person name
            client_guarantor_relationship.nil? ? nil : key_person_relationship[client_guarantor_relationship.to_s.downcase.to_sym], # key person relationship
            nil,                                                                     # nominee name
            nil,                                                                     # nominee relationship
            nil, #client.telephone_type ? phone[client.telephone_type.to_s.downcase.to_sym] : nil, # applicant telephone number type 1
            nil, #client.telephone_number,                                           # applicant telephone number number 1
            nil,                                                                     # applicant telephone number type 2
            nil,                                                                     # applicant telephone number number 2
            "D01",                                                                   # applicant address type 1
            client_address,                                                          # applicant address 1
            Branch.get(at_branch_id).name,                                               # applicant address 1 city
            states[(client_state).to_sym],                                # applicant address 1 state
            client_pincode,                                                          # applicant address 1 pincode
            nil,                                                                     # applicant address type 2
            nil,                                                                     # applicant address 2
            nil,                                                                     # applicant address 2 city
            nil,                                                                     # applicant address 2 state
            nil                                                                      # applicant address 2 pincode
           ]
  end

  private
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

  def states
    @states ||= {
      :andhra_pradesh     => "AP",
      :arunachal_pradesh  => "AR",
      :assam              => "AS",
      :bihar              => "BR",
      :chattisgarh        => "CG",
      :goa                => "GA",
      :gujarat            => "GJ",
      :haryana            => "HR",
      :himachal_pradesh   => "HP",
      :jammu_kashmir      => "JK",
      :jharkhand          => "JH",
      :karnataka          => "KA",
      :kerala             => "KL",
      :madhya_pradesh     => "MP",
      :maharashtra        => "MH",
      :manipur            => "MN",
      :meghalaya          => "ML",
      :mizoram            => "MZ",
      :nagaland           => "NL",
      :orissa             => "OR",
      :punjab             => "PB",
      :rajasthan          => "RJ",
      :sikkim             => "SK",
      :tamil_nadu         => "TN",
      :tripura            => "TR",
      :uttarakhand        => "UK",
      :uttar_pradesh      => "UP",
      :west_bengal        => "WB",
      :andaman_nicobar    => "AN",
      :chandigarh         => "CH",
      :dadra_nagar_haveli => "DN",
      :daman_diu          => "DD",
      :delhi              => "DL",
      :lakshadweep        => "LD",
      :pondicherry        => "PY"
    }
  end

end

#In-memory class for storing a LoanApplication's total information to be passed around 
class LoanApplicationInfo
    include Comparable
    attr_reader :loan_application_id, :applicant 
    attr_reader :cpv1 
    attr_reader :cpv2
    
    def initialize(loan_application_id, applicant, cpv1=nil, cpv2=nil)
      @loan_application_id = loan_application_id
      @applicant = applicant
      @cpv1 = cpv1
      @cpv2 = cpv2
    end

    #sort based on cpv recording date in the order of most-recent-first
    def <=>(other)
      return nil unless other.is_a?(LoanApplicationInfo)
      cpv_self = self.cpv2 || self.cpv1
      self_latest_cpv_at = cpv_self ? cpv_self.created_at : nil
      
      cpv_other = other.cpv2 || other.cpv1
      other_latest_cpv_at = cpv_other ? cpv_other.created_at : nil

      return nil unless (self_latest_cpv_at and other_latest_cpv_at)
      self_latest_cpv_at <=> other_latest_cpv_at
    end
end
