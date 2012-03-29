#In-memory class for storing a LoanApplication's total information to be passed around
class LoanApplicationInfo
  include Comparable
  attr_reader :loan_application_id, :client_name, :client_dob, :client_address
  attr_reader :amount, :status
  attr_reader :authorization_info
  attr_reader :cpv1
  attr_reader :cpv2

  def initialize(loan_application_id, client_name, client_dob, client_address, amount, status, authorization_info = nil, cpv1 = nil, cpv2 = nil)
    @loan_application_id = loan_application_id
    @client_name = client_name; @client_dob = client_dob; @client_address = client_address
    @amount = amount; @status = status
    @authorization_info = authorization_info if authorization_info
    @cpv1 = cpv1 if cpv1
    @cpv2 = cpv2 if cpv2
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

class LoanApplication
  include DataMapper::Resource
  include Constants::Status
  include Constants::Masters
  include Constants::Space
  include LoanApplicationWorkflow

  property :id,                  Serial
  property :status,              Enum.send('[]', *LOAN_APPLICATION_STATUSES), :nullable => false, :default => NEW_STATUS
  property :at_branch_id,        Integer, :nullable => false
  property :at_center_id,        Integer, :nullable => false
  property :created_by_staff_id, Integer, :nullable => false
  property :created_by_user_id,  Integer, :nullable => false
  property :created_at,          DateTime, :nullable => false, :default => DateTime.now
  property :created_on,          Date,     :nullable => false
  property :amount,              Float,    :nullable => false

  #basic client info
  property :client_id,           Integer,  :nullable => true
  property :client_name,         String,   :nullable => false
  property :client_dob,          Date,     :nullable => false
  property :client_address,      Text,     :nullable => false
  property :client_state,        Enum.send('[]', *STATES)
  property :client_pincode,      Integer,  :nullable => false
  property :client_reference1,   String,   :nullable => false
  property :client_reference1_type, Enum.send('[]', *REFERENCE_TYPES), :default => 'Others'
  property :client_reference2,   String,   :nullable => false
  property :client_reference2_type, Enum.send('[]', *REFERENCE_TYPES), :default => 'Others'
  property :client_guarantor_name, String, :nullable => false
  property :client_guarantor_relationship, Enum.send('[]', *RELATIONSHIPS)

  belongs_to :client, :nullable => true
  belongs_to :staff_member, :parent_key => [:id], :child_key => [:created_by_staff_id]
  belongs_to :center_cycle

  has n, :loan_file_additions
  has n, :loan_files, :through => :loan_file_additions

  has n, :client_verifications
  has 1, :loan_authorization

  validates_is_unique :client_reference1, :scope => :center_cycle_id
  validates_is_unique :client_reference2, :scope => :center_cycle_id
  validates_with_method :client_id,  :method => :is_unique_for_center_cycle?

  def is_unique_for_center_cycle?
    unless client_id.nil?
      client_ids = LoanApplication.all(:center_cycle_id => center_cycle_id).aggregate(:client_id)
      return [false, "A loan application for this client #{client_id} already exists for the current loan cycle"] if client_ids.include?(client_id)
    end
    return true
  end

  def self.create_loan_file(at_branch, at_center, for_cycle_number, scheduled_disbursal_date, scheduled_first_payment_date, by_staff, on_date, by_user, *loan_application_id)
    loan_file = LoanFile.locate_loan_file_at_center(at_branch, at_center, for_cycle_number)

    unless loan_file
      loan_file = LoanFile.generate_loan_file(at_branch, at_center, for_cycle_number, scheduled_disbursal_date, scheduled_first_payment_date, by_staff, on_date, by_user)
      raise StandardError, "Unable to create a new loan file" unless loan_file
    end
    
    lap_ids = loan_application_id
    return loan_file.loan_file_identifier unless (lap_ids and not(lap_ids.empty?))

    lap_ids_statuses = {}; lap_ids.each {|lap_id| lap_ids_statuses[lap_id] = false}
    lap_ids.each { |lap_id|
      loan_application = get(lap_id)
      if loan_application
        loan_file_addition = LoanFileAddition.add_to_loan_file(lap_id, loan_file, at_branch, at_center, for_cycle_number, by_staff, on_date, by_user)
        if loan_file_addition
          loan_application.set_status(Constants::Status::LOAN_FILE_GENERATED_STATUS)
          status_saved = loan_application.save
          lap_ids_statuses[lap_id] = status_saved
        end
      end
    }
    [loan_file.loan_file_identifier, lap_ids_statuses]
  end

  def self.add_to_loan_file(on_loan_file, at_branch, at_center, for_cycle_number, by_staff, on_date, by_user, *loan_application_id)
    lap_ids = loan_application_id
    raise ArgumentError, "No loan application IDs were supplied" unless (lap_ids and not (lap_ids.empty?))

    loan_file = LoanFile.locate_loan_file(on_loan_file)
    raise ArgumentError, "No loan file was located for loan file identifier: #{on_loan_file}" unless loan_file

    lap_ids_statuses = {}; lap_ids.each {|lap_id| lap_ids_statuses[lap_id] = false}
    lap_ids.each { |lap_id|
      loan_application = get(lap_id)
      if loan_application
        loan_file_addition = LoanFileAddition.add_to_loan_file(lap_id, loan_file, at_branch, at_center, for_cycle_number, by_staff, on_date, by_user)
        if loan_file_addition
          loan_application.set_status(Constants::Status::LOAN_FILE_GENERATED_STATUS)
          status_saved = loan_application.save
          lap_ids_statuses[lap_id] = status_saved
        end
      end
    }
    [on_loan_file, lap_ids_statuses]
  end

  # Returns the status of loan application
  def get_status
    self.status
  end

  def self.record_authorization(on_loan_application, as_status, by_staff, on_date, by_user, with_override_reason = nil)
    status_updated = false
    loan_application = get(on_loan_application)
    auth = LoanAuthorization.record_authorization(on_loan_application, as_status, by_staff, on_date, by_user, with_override_reason)
    was_saved = (not (auth.id.nil?))
    application_status = AUTHORIZATION_AND_APPLICATION_STATUSES[as_status]
    if was_saved
      loan_application.set_status(application_status)
      status_updated = loan_application.save
    end
    status_updated
  end

  # Sets the status
  def set_status(new_status)
    return false if get_status == new_status
    self.status = new_status
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
    predicates[:at_branch_id] = at_branch_id if at_branch_id
    predicates[:at_center_id] = at_center_id if at_center_id
    all(predicates).select {|lap| lap.is_pending_verification?}
  end

  def is_pending_authorization?
    self.loan_authorization.nil?
  end

  # Returns all loan applications pending authorization
  def self.pending_authorization(search_options = {})
    pending = all(search_options).select {|lap| lap.is_pending_authorization?}
    pending.collect {|lap| lap.to_info}
  end

  def self.completed_authorization(search_options = {})
    loan_applications = all(search_options)
    applications_completed_authorization = loan_applications.select { |lap|
      lap.loan_authorization
    }
    applications_completed_authorization.collect {|lap| lap.to_info}
  end

  # Is pending loan file generation
  def is_pending_loan_file_generation?
    not (self.loan_files and not (self.loan_files.empty?))
  end

  # All loan applications pending loan file generation
  def self.pending_loan_file_generation(search_options = {})
    loan_applications = all(search_options)
    applications_pending_loan_file_generation = loan_applications.select { |lap|
      lap.is_pending_loan_file_generation?
    }
    applications_pending_loan_file_generation.collect {|lap| lap.to_info}
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
    authorization_info = self.loan_authorization ? self.loan_authorization.to_info : nil
    cpvs_infos = ClientVerification.get_CPVs_infos(self.id)
    linfo = LoanApplicationInfo.new(
      self.id,
      self.client_name,
      self.client_dob,
      self.client_address,
      self.amount,
      self.get_status,
      authorization_info,
      cpvs_infos['cpv1'],
      cpvs_infos['cpv2'])
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
      id,                                                                      # member id
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

  # All searches

  def self.search(search_options = {})
    all(search_options).collect{|lap| lap.to_info}
  end
  
end
