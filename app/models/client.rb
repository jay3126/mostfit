class Client
  include Paperclip::Resource
  include DataMapper::Resource
  include DateParser  # mixin for the hook "before :valid?, :parse_dates"
  include ClientValidations, PeopleValidations
  include Constants::Masters

  before :valid?, :convert_blank_to_nil

  property :id,                       Serial
  property :guarantor_name,           String
  property :guarantor_dob,            Date
  property :guarantor_relationship,   Enum.send('[]', *RELATIONSHIPS), :default => OTHER_RELATIONSHIP
  property :telephone_number,         String, :nullable => true
  property :telephone_type,           Enum.send('[]', *TELEPHONE_TYPES), :default => DEFAULT_TELEPHONE_TYPE
  property :state,                    Enum.send('[]', *STATES)
  property :pincode,                  Integer, :max => AddressValidation::PIN_CODE_MAX_INT_VALUE
  property :income,                   Integer
  property :family_income,            Integer
  property :reference,                String, :length => 100, :nullable => false
  property :name,                     String, :length => 100, :nullable => false
  property :gender,                   Enum.send('[]', *GENDER_CHOICE), :nullable => true, :default => DEFAULT_GENDER
  property :marital_status,           Enum.send('[]', *MARITAL_STATUS), :default => DEFAULT_MARRITAL_STATUS
  property :reference_type,           Enum.send('[]', *REFERENCE_TYPES), :default => DEFAULT_REFERENCE_TYPE
  property :reference2,               String
  property :reference2_type,          Enum.send('[]', *REFERENCE2_TYPES), :default => DEFAULT_REFERENCE2_TYPE
  property :spouse_name,              String, :length => 100
  property :date_of_birth,            Date
  property :spouse_date_of_birth,     Date
  property :address,                  Text
  property :pincode,                  Integer
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

  has n, :insurance_policies
  has n, :attendances
  has n, :claims

  has n, :loan_applications

  belongs_to :client_group,         :nullable => true
  belongs_to :occupation,           :nullable => true
  belongs_to :priority_sector_list, :nullable => true
  belongs_to :psl_sub_category,     :nullable => true
  belongs_to :created_by_staff,     :child_key => [:created_by_staff_member_id], :model => 'StaffMember'
  belongs_to :created_by,           :child_key => [:created_by_user_id],    :model => 'User'

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

  def self.from_csv(row, headers)
    if center_attr = row[headers[:center]].strip
      if center   = Center.first(:name => center_attr)
      elsif center   = Center.first(:code => center_attr)
      elsif /\d+/.match(center_attr)
        center   = Center.get(center_attr)
      end
    end
    raise ArgumentError.new("No center with code/id #{center_attr}") unless center
    branch         = center.branch
    #creating group either on group ccode(if a group sheet is present groups should be already in place) or based on group name
    if headers[:group_code] and row[headers[:group_code]]
      client_group  =  ClientGroup.first(:code => row[headers[:group_code]].strip)
    elsif headers[:group] and row[headers[:group]]
      name          = row[headers[:group]].strip
      client_group  = ClientGroup.first(:name => name)||ClientGroup.create(:name => name, :center => center, :code => name.split(' ').join, :upload_id => row[headers[:upload_id]])
    else
      client_group  = nil
    end
    # client_type     = ClientType.first||ClientType.create(:type => "Standard")
    grt_date        = row[headers[:grt_date]] ? Date.parse(row[headers[:grt_date]]) : nil
    keys = [:reference, :name, :spouse_name, :date_of_birth, :address, :date_joined, :center, :grt_date, :created_by_staff, :group]
    missing_keys = keys - headers.keys
    raise ArgumentError.new("missing keys #{missing_keys.join(',')}") unless missing_keys.blank?
    hash = {:reference => row[headers[:reference]], :name => row[headers[:name]], :spouse_name => row[headers[:spouse_name]],
      :date_of_birth => Date.parse(row[headers[:date_of_birth]]), :address => row[headers[:address]],
      :date_joined => row[headers[:date_joined]], :center => center, :grt_pass_date => grt_date, :created_by => User.first,
      :created_by_staff_member_id => StaffMember.first(:name => row[headers[:created_by_staff]]).id,
      :client_group => client_group, :upload_id => row[headers[:upload_id]]}
    obj             = new(hash)
    [obj.save!, obj]
  end

  def self.search(q, per_page=10)
    if /^\d+$/.match(q)
      all(:conditions => {:id => q}, :limit => per_page)
    else
      all(:conditions => ["reference=? or reference2 or name like ?", q, q+'%'], :limit => per_page)
    end
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
    
    new_client
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