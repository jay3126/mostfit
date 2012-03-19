class LoanApplication
  include DataMapper::Resource
  include Constants::Status
  include Constants::Masters

  property :id,                  Serial
  property :status,              Enum.send('[]', *APPLICATION_STATUSES), :nullable => false, :default => Constants::Status::NEW_STATUS
  property :at_branch_id,        Integer, :nullable => false
  property :at_center_id,        Integer, :nullable => false
  property :created_by_staff_id, Integer, :nullable => false
  property :created_by_user_id,  Integer, :nullable => false
  property :created_at,          DateTime, :nullable => false, :default => DateTime.now
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
    raise ArgumentError, "Invalid client id" unless client
    return true # this is dummy
    # the logic that will decide whether a said client is allowed to file a loan application
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
  def self.recently_recorded(at_branch_id = nil, at_center_id = nil)
    predicates = {}
    if (at_branch_id and !at_branch_id.nil?)
        predicates[:at_branch_id] = at_branch_id
    end
    if (at_center_id and !at_center_id.nil?)
        predicates[:at_center_id] = at_center_id 
    end

    #take all those which are NOT pending verification
    lar = all(predicates).reject {|l|l.is_pending_verification?}
    linfos = []
    lar.each{|l| linfos.push(l.to_info)}
    linfos
  end

  #returns an object containing all information about a Loan Application
  def to_info
    debugger
    cpvs_infos = ClientVerification.get_CPVs_infos(self.id)
    linfo = LoanApplicationInfo.new(
                         self.id,
                         self.client_name,
                         cpvs_infos['cpv1'],
                         cpvs_infos['cpv2']
                    )
    linfo
  end
end

#In-memory class for storing a LoanApplication's total information to be passed around 
class LoanApplicationInfo
    attr_reader :loan_application_id, :applicant 
    attr_reader :cpv1 
    attr_reader :cpv2
    
    def initialize(loan_application_id, applicant, cpv1=nil, cpv2=nil)
       @loan_application_id = loan_application_id
       @applicant = applicant
       @cpv1 = cpv1
       @cpv2 = cpv2
    end
end
