#In-memory class for storing a LoanApplication's total information to be passed around
class LoanApplicationInfo
  include Comparable
  attr_reader :loan_application_id, :client_name, :client_dob, :client_address, :credit_bureau_status
  attr_reader :amount, :status
  attr_reader :authorization_info
  attr_reader :cpv1
  attr_reader :cpv2

  def initialize(loan_application_id, client_name, client_dob, client_address, credit_bureau_status, amount, status, authorization_info = nil, cpv1 = nil, cpv2 = nil)
    @loan_application_id = loan_application_id
    @client_name = client_name; @client_dob = client_dob; @client_address = client_address
    @credit_bureau_status = credit_bureau_status
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

  # returns the age of the client as calculated from her year of birth
  def client_age
    client_dob.nil? ? nil : (Date.today.year - client_dob.year)
  end
end

class LoanApplication
  include DataMapper::Resource
  include Constants::Status
  include Constants::Masters
  include Constants::Space
  include Constants::CreditBureau
  include LoanApplicationWorkflow
  include ClientValidations
  include ClientAgeValidations
  include Constants::Properties
  include Comparable
  include CommonClient::Validations
  include Constants::ReferenceFormatValidations

  property :id,                             Serial
  property :status,                         Enum.send('[]', *LOAN_APPLICATION_STATUSES), :nullable => false, :default => NEW_STATUS
  property :at_branch_id,                   Integer,  :nullable => false
  property :at_center_id,                   Integer,  :nullable => false
  property :created_by_staff_id,            Integer,  :nullable => false
  property :created_by_user_id,             Integer,  :nullable => false
  property :created_at,                     DateTime, :nullable => false, :default => DateTime.now
  property :updated_at,                     DateTime, :nullable => false, :default => DateTime.now
  property :created_on,                     Date,     :nullable => false
  property :amount,                         *MONEY_AMOUNT
  property :currency,                       *CURRENCY
  property :credit_bureau_status,           Enum.send('[]', *CREDIT_BUREAU_STATUSES), :default => Constants::CreditBureau::NO_MATCH
  property :credit_bureau_rated_at,         DateTime
  
  #basic client info
  property :client_id,                      Integer,  :nullable => true
  property :client_name,                    String, CommonClient::Validations.get_validation(:client_name, LoanApplication)
  property :client_dob,                     Date
  property :client_address,                 Text, CommonClient::Validations.get_validation(:client_address, LoanApplication)
  property :client_state,                   Enum.send('[]', *STATES)
  property :client_pincode,                 Integer, CommonClient::Validations.get_validation(:client_pincode, LoanApplication)
  property :client_reference1,              String, CommonClient::Validations.get_validation(:client_reference1, LoanApplication)
  property :client_reference1_type,         Enum.send('[]', *REFERENCE_TYPES), CommonClient::Validations.get_validation(:client_reference1_type, LoanApplication)
  property :client_reference2,              String, CommonClient::Validations.get_validation(:client_reference2, LoanApplication)
  property :client_reference2_type,         Enum.send('[]', *REFERENCE_TYPES), CommonClient::Validations.get_validation(:client_reference2_type, LoanApplication)
  property :client_guarantor_name,          String, CommonClient::Validations.get_validation(:client_guarantor_name, LoanApplication)
  property :client_guarantor_relationship,  Enum.send('[]', *RELATIONSHIPS), CommonClient::Validations.get_validation(:client_guarantor_relationship, LoanApplication)

  belongs_to :client, :nullable => true
  belongs_to :staff_member, :parent_key => [:id], :child_key => [:created_by_staff_id]
  belongs_to :center_cycle

  has n, :loan_file_additions
  has n, :loan_files, :through => :loan_file_additions

  has n, :client_verifications
  has 1, :loan_authorization
  has 1, :loan

  validates_length :client_name, :min => 3
  validates_present   :client_dob
  validates_with_method :client_dob, :method => :permissible_age_for_credit?
  validates_with_method :client_id,  :method => :is_unique_for_center_cycle?

  def money_amounts; [:amount]; end
  def loan_money_amount; to_money_amount(:amount); end

  def <=>(other)
    return nil unless (other.respond_to?(:updated_at) and other.respond_to?(:created_at))
    compare_on_updated_at = other.updated_at <=> self.updated_at
    (compare_on_updated_at == 0) ? (other.created_at <=> self.created_at) : compare_on_updated_at
  end

  # Returns a list of the client IDs for loan applications in progress at the center
  # for the specified center cycle
  # TODO: Remove the reference to the 'physical' center cycle with a center cycle number
  # We should resolve the center cycle using just the center and center cycle number
  # @param for_center_id  [Integer]
  # @param for_center_cycle [Object]
  def self.all_loan_application_client_ids_for_center_cycle(for_center_id, for_center_cycle)
    raise ArgumentError, "No center cycle available at center #{for_center_id}" unless (for_center_cycle and (for_center_cycle.cycle_number > 0))
    all(:at_center_id => for_center_id, :center_cycle_id => for_center_cycle.id).aggregate(:client_id).compact
  end

  #mapping of loan application to client 
  def to_client
    _to_client = {
      :name                       => client_name,
      :reference                  => client_reference1,
      :reference_type             => client_reference1_type,
      :reference2                 => client_reference2,
      :reference2_type            => client_reference2_type,
      :date_of_birth              => client_dob,
      :address                    => client_address,
      :pincode                    => client_pincode,
      :state                      => client_state,
      :guarantor_name             => client_guarantor_name,
      :guarantor_relationship     => client_guarantor_relationship,
      :created_by_staff_member_id => created_by_staff_id,
      :created_by_user_id         => created_by_user_id,
      :center_id                  => at_center_id,
      :date_joined                => created_on
    }
  end

  def self.get_all_loan_applications_for_branch_and_center(search_options = {})
    LoanApplication.all(search_options)
  end
  
  #creates a client for this particular loan application
  def create_client
    return self.client if self.client

    administered_at_location_id = self.at_center_id
    registered_at_location_id = self.at_branch_id
    client_hash = self.to_client
    client_for_loan_application = Client.record_client(client_hash, administered_at_location_id, registered_at_location_id)
    self.client = client_for_loan_application
    save
    raise Errors::DataError, "Unable to create and set the client for the loan application" unless self.saved?
    self.client
  end

  
  def create_loan(loan_params = {})
    raise ArgumentError if loan_params.blank? and !(loan_params.is_a?(Hash))
    loan_params.merge!(:client_id => self.client_id)
    loan = nil
    return loan if (self.client_id.nil? || !(self.loan.nil?))
    Loan.transaction do |t|
      loan = Loan.create(loan_params)
      self.loan = loan
      t.rollback unless loan.saved? and self.save
    end
    loan
  end

  def is_unique_for_center_cycle?
    unless client_id.nil? or self.saved?
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

  # Sets the status of the loan application if the status is conformant iwht the loan application workflow
  #
  # @param  [String] has to be one of the statuses of Constants::Status::LOAN_APPLICATION_STATUSES
  # @return [Boolean] returns true if the status is saved else false 
  def set_status(new_status)
    return [false, "The loan application already has this status"] if get_status == new_status
    return [false, "The #{get_status} being tried to save is not a part of the LOAN application statuses"] unless LOAN_APPLICATION_STATUSES.include?(new_status)
    
    # checks to make sure that the new_status does that needs to be saved does not precede the current status in the loan application workflow
    return [false, "The status is being updated as new"] if CREATION_STATUSES.include?(new_status) 
    return [false, "Loan Application status cannot change from #{get_status} to #{new_status}"] if (DEDUPE_STATUSES.include?(new_status) and (OVERLAP_REPORT_STATUSES.include?(get_status) or AUTHORIZATION_STATUSES.include?(get_status) or CPV_STATUSES.include?(get_status) or LOAN_FILE_GENERATION_STATUSES.include?(get_status)))
    return [false, "Loan Application status cannot change from #{get_status} to #{new_status}"] if (OVERLAP_REPORT_STATUSES.include?(new_status) and (AUTHORIZATION_STATUSES.include?(get_status) or CPV_STATUSES.include?(get_status) or LOAN_FILE_GENERATION_STATUSES.include?(get_status)))
    return [false, "Loan Application status cannot change from #{get_status} to #{new_status}"] if (AUTHORIZATION_STATUSES.include?(new_status) and (CPV_STATUSES.include?(get_status) or LOAN_FILE_GENERATION_STATUSES.include?(get_status) or CREATION_STATUSES.include?(get_status) or DEDUPE_STATUSES.include?(get_status)))
    return [false, "Loan Application status cannot change from #{get_status} to #{new_status}"] if (CPV_STATUSES.include?(new_status) and ((LOAN_FILE_GENERATION_STATUSES.include?(get_status)) or CREATION_STATUSES.include?(get_status) or OVERLAP_REPORT_STATUSES.include?(get_status) or DEDUPE_STATUSES.include?(get_status)))

    # for all dead end statuses
    return [false, "Loan Application status cannot proceed further from the current status: #{get_status}"] if get_status == CONFIRMED_DUPLICATE_STATUS
    return [false, "Loan Application status cannot proceed further from the current status: #{get_status}"] if get_status == CPV1_REJECTED_STATUS
    return [false, "Loan Application status cannot proceed further from the current status: #{get_status}"] if get_status == CPV2_REJECTED_STATUS
    self.update(:status => new_status)
  end

  # FUNCTIONS THAT SET STATUS FOR LOAN APPLICATIONS AND ARE GATE KEEPER FUNCTIONS AS LOAN APPLICATIONS PROCEED THROUGH THE LOAN APPLICATION WORKFLOW
  def generate_credit_bureau_request
    status = nil
    OverlapReportRequest.transaction do |t|
      OverlapReportRequest.create(:loan_application_id => self.id)
      status = self.set_status(OVERLAP_REPORT_REQUEST_GENERATED_STATUS) 
      t.rollback unless status == true
    end
    return status
  end

  def record_credit_bureau_response(credit_bureau_status)
    status = nil
    LoanApplication.transaction do |t|
      status = self.set_status(OVERLAP_REPORT_RESPONSE_MARKED_STATUS)
      self.update(:credit_bureau_status => credit_bureau_status, :credit_bureau_rated_at => DateTime.now)
      t.rollback unless status == true
    end
    return status
  end

  def record_CPV1_approved(by_staff, on_date, by_user_id)
    status = nil
    ClientVerification.transaction do |t|
      ClientVerification.record_CPV1_approved(self.id, by_staff, on_date, by_user_id) 
      status = self.set_status(CPV1_APPROVED_STATUS)
      t.rollback unless status == true
    end
    return status
  end

  def record_CPV1_rejected(by_staff, on_date, by_user_id)
    status = nil
    ClientVerification.transaction do |t|
      ClientVerification.record_CPV1_rejected(self.id, by_staff, on_date, by_user_id) 
      status = self.set_status(CPV1_REJECTED_STATUS)
      t.rollback unless status == true
    end
    return status
  end
  
  def record_CPV2_approved(by_staff, on_date, by_user_id)
    status = nil
    ClientVerification.transaction do |t|
      ClientVerification.record_CPV2_approved(self.id, by_staff, on_date, by_user_id) 
      status = self.set_status(CPV2_APPROVED_STATUS)
      t.rollback unless status == true
    end
    return status
  end

  def record_CPV2_rejected(by_staff, on_date, by_user_id)
    status = nil
    ClientVerification.transaction do |t|
      ClientVerification.record_CPV2_rejected(self.id, by_staff, on_date, by_user_id) 
      status = self.set_status(CPV2_REJECTED_STATUS)
      t.rollback unless status == true
    end
    return status
  end

  def self.record_authorization(on_loan_application, as_status, by_staff, on_date, by_user, with_override_reason = nil)
    status_updated = false
    loan_application = get(on_loan_application)
    auth = LoanAuthorization.record_authorization(on_loan_application, as_status, by_staff, on_date, by_user, with_override_reason)
    was_saved = (not (auth.id.nil?))
    application_status = AUTHORIZATION_AND_APPLICATION_STATUSES[as_status]
    status_updated = loan_application.set_status(application_status) if was_saved
    raise ArgumentError, "#{auth.errors.first}" unless was_saved
    status_updated
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

  #returns all loan applications which are pending for overlap report requests generation
  def self.pending_overlap_report_request_generation(search_options ={})
    eligible_statuses = [NOT_DUPLICATE_STATUS, CLEARED_NOT_DUPLICATE_STATUS]
    search_options.merge!(:status => eligible_statuses)
    pending = all(search_options)
  end

  #returns all loan applications which are pending for CPV1 and/or CPV2
  def self.pending_CPV(search_options = {})
    search_options.merge!(:status => [AUTHORIZED_APPROVED_STATUS, AUTHORIZED_APPROVED_OVERRIDE_STATUS, CPV1_APPROVED_STATUS])
    all(search_options)
  end

  def self.check_loan_authorization_status(credit_bureau_status, authorization_status)
    if credit_bureau_status == RATED_NEGATIVE && authorization_status == APPLICATION_APPROVED
      APPLICATION_OVERRIDE_APPROVED
    elsif credit_bureau_status == RATED_NEGATIVE && authorization_status == APPLICATION_REJECTED
      APPLICATION_REJECTED
    elsif credit_bureau_status == RATED_POSITIVE && authorization_status == APPLICATION_APPROVED
      APPLICATION_APPROVED
    elsif credit_bureau_status == RATED_POSITIVE && authorization_status == APPLICATION_REJECTED
      APPLICATION_OVERRIDE_REJECTED
    elsif credit_bureau_status == NO_MATCH && authorization_status == APPLICATION_REJECTED
      APPLICATION_OVERRIDE_REJECTED
    elsif credit_bureau_status == NO_MATCH && authorization_status == APPLICATION_APPROVED
      APPLICATION_OVERRIDE_APPROVED
    end
  end
  
  def self.pending_authorization(search_options = {})
    search_options.merge!(:status => OVERLAP_REPORT_RESPONSE_MARKED_STATUS)
    pending = all(search_options)
    pending.collect {|lap| lap.to_info}
  end

  def self.completed_authorization(search_options = {})
    search_options.merge!(:status => AUTHORIZATION_STATUSES, :order => [:updated_at.desc])
    all(search_options)
    #    loan_applications.collect {|lap| lap.to_info}
  end

  # Is pending loan file generation
  def is_pending_loan_file_generation?
    not (self.loan_files and not (self.loan_files.empty?))
  end

  # All loan applications pending loan file generation
  def self.pending_loan_file_generation(search_options = {})
    search_options[:status] = CPV2_APPROVED_STATUS
    loan_applications = all(search_options)
    applications_pending_loan_file_generation = loan_applications#.select { |lap|
    #   lap.is_pending_loan_file_generation?
    # }
    applications_pending_loan_file_generation.collect {|lap| lap.to_info}
  end

  #returns all loan applications for which CPV was recently recorded
  def self.recently_recorded_client_verifications(search_options = {})
    cpv_completed_statuses = [CPV1_APPROVED_STATUS, CPV1_REJECTED_STATUS, CPV2_APPROVED_STATUS, CPV2_REJECTED_STATUS]
    search_options.merge!({:status => cpv_completed_statuses})
    recent = all(search_options)
    recent.collect{|lap| lap.to_info}
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

  # returns all loan applications which are pending for de-dupe process
  def self.pending_dedupe
    all(:status => NEW_STATUS)
  end

  # returns all loan applications which has status not_duplicate
  def self.not_duplicate
    all(:status => NOT_DUPLICATE_STATUS)
  end

  # returns all loan applications which has status suspected_duplicate
  def self.suspected_duplicate(search_options = {})
    search_options.merge!(:status => SUSPECTED_DUPLICATE_STATUS)
    all(search_options)
  end

  # set loan application status as cleared_not_duplicate
  def self.set_cleared_not_duplicate(loan_application_id)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    is_saved = loan_application.set_status(CLEARED_NOT_DUPLICATE_STATUS)
    raise ArgumentError, "Client ID #{loan_application.client_id} : #{loan_application.errors.to_a}" unless is_saved
    return true if is_saved
  end

  # set loan application status as confirm_duplicate
  def self.set_confirm_duplicate(loan_application_id)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    is_saved = loan_application.set_status(CONFIRMED_DUPLICATE_STATUS)
    raise ArgumentError, "Client ID #{loan_application.client_id} : #{loan_application.errors.to_a}" unless is_saved
    return true if is_saved
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
      self.credit_bureau_status,
      self.loan_money_amount,
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
      BizLocation.get(at_branch_id).name,                                               # applicant address 1 city
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
