class Client
  include Paperclip::Resource
  include DataMapper::Resource
  include DateParser  # mixin for the hook "before :valid?, :parse_dates"
  include ClientValidations, PeopleValidations
  include Constants::Masters
  include CommonClient::Validations
  include Constants::Client
  include Identified

  before :valid?, :convert_blank_to_nil

  property :id,                       Serial
  property :guarantor_name,           String, CommonClient::Validations.get_validation(:guarantor_name, Client)
  property :guarantor_dob,            Date
  property :guarantor_relationship,   Enum.send('[]', *RELATIONSHIPS), CommonClient::Validations.get_validation(:guarantor_relationship, Client)
  property :telephone_number,         String, :nullable => true
  property :telephone_type,           Enum.send('[]', *TELEPHONE_TYPES), :default => DEFAULT_TELEPHONE_TYPE
  property :state,                    String, :default => ''
  property :pincode,                  Integer, CommonClient::Validations.get_validation(:pincode, Client)
  property :income,                   Integer
  property :family_income,            Integer
  property :reference,                String, CommonClient::Validations.get_validation(:reference, Client)
  property :name,                     String, CommonClient::Validations.get_validation(:name, Client)
  property :gender,                   Enum.send('[]', *GENDER_CHOICE), :nullable => true, :default => DEFAULT_GENDER
  property :marital_status,           Enum.send('[]', *MARITAL_STATUS), :default => DEFAULT_MARRITAL_STATUS
  property :reference_type,           Enum.send('[]', *REFERENCE_TYPES), CommonClient::Validations.get_validation(:reference_type, Client)
  property :reference2,               String, CommonClient::Validations.get_validation(:client_reference2, LoanApplication)
  property :reference2_type,          Enum.send('[]', *REFERENCE2_TYPES), CommonClient::Validations.get_validation(:reference2_type, Client)
  property :spouse_name,              String, :length => 100
  property :date_of_birth,            Date
  property :spouse_date_of_birth,     Date
  property :address,                  Text, CommonClient::Validations.get_validation(:address, Client)
  property :active,                   Boolean, :default => true, :nullable => false
  property :inactive_reason,          Enum.send('[]', *INACTIVE_REASONS), :nullable => true, :default => ''
  property :date_joined,              Date
  property :grt_pass_date,            Date, :nullable => true
  property :center_id,                Integer, :nullable => true
  property :created_at,               DateTime, :default => Time.now
  property :deleted_at,               ParanoidDateTime
  property :updated_at,               DateTime
  property :deceased_on,              Date
  property :created_by_user_id,       Integer, :nullable => false
  property :other_income,             Integer, :length => 10, :nullable => true
  property :total_income,             Integer, :length => 10, :nullable => true
  property :poverty_status,           String, :length => 10, :nullable => true
  property :caste,                    Enum.send('[]', *CASTE_CHOICE), :nullable => true, :default => CASTE_NOT_SPECIFIED
  property :religion,                 Enum.send('[]', *RELIGION_CHOICE), :nullable => true, :default => DEFAULT_RELIGION
  property :created_by_staff_member_id,  Integer, :nullable => false
  property :claim_document_status,       Enum.send('[]', *CLAIM_DOCUMENTS_STATUS), :default => CLAIM_DOCUMENTS_PENDING
  property :claim_document_recieved_by,  Integer
  property :cliam_document_recieved_on,  Date
  property :town_classification,           Enum.send('[]', *TOWN_CLASSIFICATION), :nullable => true, :default => DEFAULT_CLASSIFICATION

  has n, :simple_insurance_policies
  has 1, :death_event, 'DeathEvent', :parent_key => [:id], :child_key => [:affected_client_id]
  has n, :attendance_records, :parent_key => [:id], :child_key => [:counterparty_id]
  has 1, :claim

  has n, :loan_applications

  belongs_to :client_group,         :nullable => true
  belongs_to :occupation,           :nullable => true
  belongs_to :priority_sector_list, :nullable => true
  belongs_to :psl_sub_category,     :nullable => true
  belongs_to :created_by_staff,     :child_key => [:created_by_staff_member_id], :model => 'StaffMember'
  belongs_to :created_by,           :child_key => [:created_by_user_id],    :model => 'User'
  belongs_to :upload, :nullable => true

  validates_with_method :is_there_space_in_the_client_group?

  has_attached_file :picture,
    :styles => {:medium => "300x300>", :thumb => "60x60#"},
    :url => "/uploads/:class/:id/:attachment/:style/:basename.:extension",
    :path => "#{Merb.root}/public/uploads/:class/:id/:attachment/:style/:basename.:extension",
    :default_url => "/images/no_photo.jpg"

  has_attached_file :application_form,
    :styles => {:medium => "300x300>", :thumb => "60x60#"},
    :url => "/uploads/:class/:id/:attachment/:style/:basename.:extension",
    :path => "#{Merb.root}/public/uploads/:class/:id/:attachment/:style/:basename.:extension"

  has_attached_file :fingerprint,
    :url => "/uploads/:class/:id/:basename.:extension",
    :path => "#{Merb.root}/public/uploads/:class/:id/:basename.:extension"

  validates_length    :name, :min => 3
  validates_present   :date_joined
  validates_is_unique :reference
  validates_is_unique :reference2
  validates_attachment_thumbnails :picture
  validates_with_method :date_joined, :method => :dates_make_sense
  validates_with_method :date_of_birth, :method => :permissible_age_for_credit?


  def created_on; self.date_joined; end
  def counterparty; self; end

  def is_there_space_in_the_client_group?
    if (self.client_group and self.client_group.nil? and self.client_group.clients and self.new?)
      return [false, "The number of clients in this group exceeds the maximum number of members permissible"] if self.client_group.clients.count > self.client_group.number_of_members
    end
    return true
  end

  def self.from_csv(row, headers)
    center = BizLocation.first(:name => row[headers[:center]])
    raise ArgumentError, "Center(#{row[headers[:center]]}) does not exist" if center.blank?

    branch = LocationLink.get_parent(center, Date.parse(row[headers[:date_joined]])) if center
    #creating group either on group code(if a group sheet is present groups should be already in place) or based on group name
    if headers[:group_code] and row[headers[:group_code]]
      client_group  =  ClientGroup.first(:code => row[headers[:group_code]].strip)
    elsif headers[:client_group] and row[headers[:client_group]]
      name          = row[headers[:client_group]].strip
      client_group  = ClientGroup.first(:name => name)||ClientGroup.create(:name => name, :biz_location_id => center.id, :code => name.split(' ').join, :upload_id => row[headers[:upload_id]], :created_by_staff_member_id => StaffMember.first(:name => row[headers[:created_by_staff]]).id, :creation_date => Date.parse(row[headers[:date_joined]]))
    else
      client_group  = nil
    end

    hash = {:name => row[headers[:name]], :gender => row[headers[:gender]], :reference => row[headers[:reference]],
      :reference_type => Constants::Masters::RATION_CARD, :reference2 => row[headers[:reference2]],
      :reference2_type => row[headers[:reference2_type]], :date_of_birth => Date.parse(row[headers[:date_of_birth]]),
      :date_joined => Date.parse(row[headers[:date_joined]]), :client_group => client_group,
      :center_id => BizLocation.first(:name => row[headers[:center]]).id, :guarantor_name => row[headers[:guarantor_name]],
      :guarantor_dob => Date.parse(row[headers[:guarantor_date_of_birth]]), :guarantor_relationship => row[headers[:guarantor_relationship]],
      :spouse_name => row[headers[:spouse_name]], :spouse_date_of_birth => row[headers[:spouse_date_of_birth]], :address => row[headers[:address]],
      :pincode => row[headers[:pincode]], :created_by_staff_member_id => StaffMember.first(:name => row[headers[:created_by_staff]]).id,
      :created_by_user_id => User.first.id, :upload_id => row[headers[:upload_id]]}

    obj = create_client(hash, center.id, branch.id)
    [obj.save!, obj]
  end

  def self.search(q, search_on = nil, per_page=10)
    if /^\d+$/.match(q) && search_on == nil
      clients = all(:conditions => {:id => q}, :limit => per_page)
    else
      clients = all(:conditions => ["reference=? or reference2=? or name like ?", q, q, q+'%'], :limit => per_page)
      if clients.blank?
        q = q.gsub(/[^0-9]/, '')
        clients = all(:conditions => ["reference=? ", q], :limit => per_page)
      end
    end
    clients
  end

  def to_loan_application
    _to_loan_application = {
      :client_id              => id,
      :client_name            => name,
      :client_dob             => date_of_birth,
      :client_address         => address,
      :client_state           => state,
      :client_pincode         => pincode,
      :client_reference1      => reference,
      :client_reference1_type => reference_type,
      :client_reference2      => reference2,
      :client_reference2_type => reference2_type,
      :client_guarantor_name  => guarantor_name,
      :client_guarantor_relationship => guarantor_relationship
    }
  end

  def self.record_client(client_hash, administered_at_location_id, registered_at_location_id)
    Validators::Arguments.not_nil?(client_hash, administered_at_location_id, registered_at_location_id)

    administered_at = BizLocation.get(administered_at_location_id)
    raise ArgumentError, "Unable to determine the administered location for client" unless administered_at

    registered_at = BizLocation.get(registered_at_location_id)
    raise ArgumentError, "Unable to determine the registered location for client" unless registered_at

    new_client = create(client_hash)
    raise Errors::DataError, new_client.errors.first.first unless new_client.saved?

    effective_on = new_client.date_joined
    performed_by = new_client.created_by_staff_member_id
    recorded_by  = new_client.created_by_user_id
    ClientAdministration.assign(administered_at, registered_at, new_client, performed_by, recorded_by, effective_on)
    AccountsChart.setup_counterparty_accounts_chart(new_client)
    
    new_client
  end

  def self.create_client(fields, admin_location_id, reg_location_id)
    
    client = Client.new(fields)
    admin_location = BizLocation.get admin_location_id
    reg_location = BizLocation.get reg_location_id
    raise Errors::DataError, client.errors.first.join(', ') unless client.valid?
    valid = Validators::Assignments.is_valid_assignment_date?(client.date_joined, admin_location, reg_location)
    raise Errors::DataError, valid.last unless valid == true
    client.save
    ClientAdministration.assign(admin_location, reg_location , client, client.created_by_staff_member_id, client.created_by_user_id, client.date_joined)
    AccountsChart.setup_counterparty_accounts_chart(client)
    client
  end

  def self.client_has_outstanding_loan?(client)
    facade = FacadeFactory.instance.get_instance(FacadeFactory::CLIENT_FACADE, User.first)
    client_loans = facade.get_all_loans_for_counterparty(client)
    active_loan = 0
    unless client_loans.blank?
      client_loans.compact.each do |loan|
        active_loan += 1 if loan.is_outstanding?
      end
    end
    return (client_loans.blank? || active_loan == 0) ? false : true
  end

  def self.mark_client_as_inactive(client)
    client.active = false
    client.save
    raise Errors::DataError, client.errors.first.first unless client.saved?
  end

  def self.is_client_active?(client)
    return client.active == true ? true : false
  end

  def self.mark_client_documents_recieved(client, recieved_by, recieved_on)
    client.claim_document_status = Constants::Client::CLAIM_DOCUMENTS_RECEIVED
    client.claim_document_recieved_by = recieved_by
    client.cliam_document_recieved_on = recieved_on
    client.save
    raise Errors::DataError, client.errors.first.first unless client.saved?
  end

  def self.is_claim_processing_or_inactive?(client)
    return client.active == false || client.claim_document_status == Constants::Client::CLAIM_DOCUMENTS_RECEIVED ? true : false
  end

  def self.client_death_documents_recieved?(client)
    death_event = DeathEvent.first(:affected_client_id => client.id)
    unless death_event.blank?
      return client.claim_document_status == Constants::Client::CLAIM_DOCUMENTS_RECEIVED ? true :false
    end
  end

  def self.client_has_death_event?(client)
    death_event = DeathEvent.first(:affected_client_id => client.id)
    return death_event.blank? ? false : true
  end

  def update_client_details_in_bulk(client_hash)
    update_client = update(client_hash)
    raise Errors::DataError, self.errors.first unless update_client
  end

  def self.death_event_filed_for(client)
    death_event = DeathEvent.first(:affected_client_id => client.id)
    death_event.relationship_to_client == "Self relationship" ? "Client" : death_event.relationship_to_client
  end

  def self.get_all_counterparty_outstanding_loan(client)
    facade = FacadeFactory.instance.get_instance(FacadeFactory::CLIENT_FACADE, User.first)
    client_loans = facade.get_all_loans_for_counterparty(client)
    active_loan = []
    unless client_loans.blank?
      client_loans.compact.each do |loan|
        active_loan << loan if loan.is_outstanding?
      end
    end
    active_loan
  end

  def move_client?
    facade = FacadeFactory.instance.get_instance(FacadeFactory::CLIENT_FACADE, User.first)
    client_loans = facade.get_all_loans_for_counterparty(self)
    loan_status = [:repaid_loan_status, :preclosed_loan_status]
    loans = client_loans.select{|loan| !loan_status.include?(loan.status)}
    loans.blank?
  end

  def client_psl_sub_category_list
    psl_id = self.priority_sector_list_id
    sub_psl_id = self.psl_sub_category_id
    collection_sub_psl = []
    if psl_id.blank?
      return [nil, nil]
    else
      psl = PrioritySectorList.get(psl_id)
      collection_sub_psl = psl.psl_sub_categories
      selected_sub_psl = sub_psl_id.blank? ? nil : PslSubCategory.get(sub_psl_id)
      return [collection_sub_psl, selected_sub_psl]
    end
  end

  private
  
  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.send(k).type==Integer
        self.send("#{k}=", nil)
      end
    }
    self.occupation = nil if self.occupation.blank?
  end

  def dates_make_sense
    return true if not grt_pass_date or not date_joined
    return [false, "Client cannot join this center before the center was created"] if center and center.creation_date and center.creation_date > date_joined
    return [false, "GRT Pass Date cannot be before Date Joined"]  if grt_pass_date < date_joined
    return [false, "Client cannot die before he became a client"] if deceased_on and (deceased_on < date_joined or deceased_on < grt_pass_date)
    true
  end

end
