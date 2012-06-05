=begin

module Constants
  namespace Client
    
  end
end
=end

class Client
  include Paperclip::Resource
  include DateParser  # mixin for the hook "before :valid?, :parse_dates"
  include DataMapper::Resource
  include FeesContainer

  FLAGS = [:insincere]

  before :valid?, :parse_dates
  before :valid?, :convert_blank_to_nil
  before :valid?, :add_created_by_staff_member
  after  :save,   :check_client_deceased
  after  :save,   :levy_fees
  after  :save,   :update_loan_cache
  
  GENDER = ['', 'female', 'male']

  property :id,              Serial
  property :reference,       String, :length => 100, :nullable => false, :index => true
  property :name,            String, :length => 100, :nullable => false, :index => true
  property :gender,     Enum.send('[]', *GENDER), :nullable => true, :lazy => true, :default => 'female'
  property :spouse_name,     String, :length => 100, :lazy => true
  property :date_of_birth,   Date,   :index => true, :lazy => true
  property :spouse_date_of_birth, Date, :index => true, :lazy => true
  #property :address,         Text, :lazy => true
  property :active,          Boolean, :default => true, :nullable => false, :index => true
  property :inactive_reason, Enum.send('[]', *INACTIVE_REASONS), :nullable => true, :index => true, :default => ''
  property :date_joined,     Date,    :index => true
  property :grt_pass_date,   Date,    :index => true, :nullable => true
  property :client_group_id, Integer, :index => true, :nullable => true
  property :center_id,       Integer, :index => true, :nullable => true
  property :created_at,      DateTime, :default => Time.now
  property :deleted_at,      ParanoidDateTime
  property :updated_at,      DateTime
  property :deceased_on,     Date, :lazy => true
  #property :client_type,     Enum["standard", "takeover"] #, :default => "standard"
  property :created_by_user_id,  Integer, :nullable => false, :index => true
  property :created_by_staff_member_id,  Integer, :nullable => false, :index => true
  property :verified_by_user_id, Integer, :nullable => true, :index => true
  property :tags, Flag.send("[]", *FLAGS)

  property :account_number, String, :length => 20, :nullable => true, :lazy => true
  property :type_of_account, Enum.send('[]', *['', 'savings', 'current', 'no_frill', 'fixed_deposit', 'loan', 'other']), :lazy => true
  property :bank_name,      String, :length => 20, :nullable => true, :lazy => true
  property :bank_branch,         String, :length => 20, :nullable => true, :lazy => true
  property :join_holder,    String, :length => 20, :nullable => true, :lazy => true
#  property :client_type,    Enum[:default], :default => :default
  property :number_of_family_members, Integer, :length => 10, :nullable => true, :lazy => true
  property :other_productive_asset, String, :length => 30, :nullable => true, :lazy => true
  property :income_regular, Enum.send('[]', *['', 'no', 'yes']), :default => '', :nullable => true, :lazy => true
  property :client_migration, Enum.send('[]', *['', 'no', 'yes']), :default => '', :nullable => true, :lazy => true
  property :pr_loan_amount, Integer, :length => 10, :nullable => true, :lazy => true
  property :other_income, Integer, :length => 10, :nullable => true, :lazy => true
  property :total_income, Integer, :length => 10, :nullable => true, :lazy => true
  property :poverty_status, String, :length => 10, :nullable => true, :lazy => true
  
  property :caste, Enum.send('[]',*CASTES), :lazy => true, :nullable => false, :default => 'General'
    
  #how do I make the Spouse Name allowed (and compulsory) only if the Marital Status says Married (guessing we don't record for Seperated and Widow)
  property :marital_status, Enum.send('[]', *['','Married','Unmarried','Widow','Seperated']), :nullable => false, :lazy => true 
  
  #how do I make either this OR the DoB field fillable ? Not both at any given time.
  property :age, String, :length => 3, :nullable => false, :lazy => true
  
  #residence properties
  property :house_name, String, :length => 30, :nullable => false, :lazy => true
  property :place, String, :length => 30, :nullable => false, :lazy => true
  #should we make this a Enum of Kerala Districts to standardize input ?
  property :district, String, :length => 20, :nullable => false, :lazy => true
  property :village_or_panchayat, String, :length => 40, :nullable => true, :lazy => true
  property :taluka, String, :length => 40, :nullable => false, :lazy => true
  property :block, String, :length => 40, :nullable => true, :lazy => true
  property :ward_number, String, :length => 3, :nullable => true, :lazy => true
  property :house_number, String, :length => 3, :nullable => true, :lazy => true
  property :physically_handicapped, Boolean, :default => false, :nullable => false, :lazy => true

  #family information 
  RELATIONSHIP = ['', 'spouse','brother','sister', 'father', 'mother', 'son', 'daughter']
  property :family_1_name, String, :lazy => true
  property :family_1_gender, Enum.send('[]', *GENDER), :lazy => true, :nullable => true
  property :family_1_age, Integer, :lazy => true
  property :family_1_relationship, Enum.send('[]', *RELATIONSHIP), :lazy => true, :nullable => true
  property :family_1_occupation, Integer, :lazy => true #this will come from the resource Occupation
  property :family_1_monthly_income, Integer, :lazy => true

  property :family_2_name, String, :lazy => true
  property :family_2_gender, Enum.send('[]', *GENDER), :lazy => true, :nullable => true
  property :family_2_age, Integer, :lazy => true
  property :family_2_relationship, Enum.send('[]', *RELATIONSHIP), :lazy => true, :nullable => true
  property :family_2_occupation, Integer, :lazy => true
  property :family_2_monthly_income, Integer, :lazy => true

  property :family_3_name, String, :lazy => true
  property :family_3_gender, Enum.send('[]', *GENDER), :lazy => true, :nullable => true
  property :family_3_age, Integer, :lazy => true
  property :family_3_relationship, Enum.send('[]', *RELATIONSHIP), :lazy => true, :nullable => true
  property :family_3_occupation, Integer, :lazy => true
  property :family_3_monthly_income, Integer, :lazy => true

  property :family_4_name, String, :lazy => true
  property :family_4_gender, Enum.send('[]', *GENDER), :lazy => true, :nullable => true
  property :family_4_age, Integer, :lazy => true
  property :family_4_relationship, Enum.send('[]', *RELATIONSHIP), :lazy => true, :nullable => true
  property :family_4_occupation, Integer, :lazy => true
  property :family_4_monthly_income, Integer, :lazy => true

  property :family_5_name, String, :lazy => true
  property :family_5_gender, Enum.send('[]', *GENDER), :lazy => true, :nullable => true
  property :family_5_age, Integer, :lazy => true
  property :family_5_relationship, Enum.send('[]', *RELATIONSHIP), :lazy => true, :nullable => true
  property :family_5_occupation, Integer, :lazy => true
  property :family_5_monthly_income, Integer, :lazy => true

  property :family_6_name, String, :lazy => true
  property :family_6_gender, Enum.send('[]', *GENDER), :lazy => true, :nullable => true
  property :family_6_age, Integer, :lazy => true
  property :family_6_relationship, Enum.send('[]', *RELATIONSHIP), :lazy => true, :nullable => true
  property :family_6_occupation, Integer, :lazy => true
  property :family_6_monthly_income, Integer, :lazy => true
  
  property :total_monthly_income, Integer, :lazy => true

  property :have_physically_handicapped_family_members, Boolean, :default => false, :lazy => true, :nullable => false 
  ########socio-economic details#########
  property :house_type, Enum.send('[]',*HOUSE_TYPES), :lazy => true, :nullable => false, :default => 'Thatched'
  property :have_other_valuable_property, Boolean, :default => false, :lazy => true, :nullable => false
  property :productive_land, Boolean, :lazy => true, :nullable => false, :default => true

  property :own_four_wheeler, Boolean, :lazy => true, :nullable => false, :default => false

  property :own_two_wheeler, Boolean, :lazy => true, :nullable => false, :default => false

  #more chances of a MFI Customer owning a cycle ;)
  property :own_a_cycle, Boolean, :lazy => true, :nullable => false, :default => true

  #basic amenities 
  property :drinking_water_provision, Enum.send('[]',*DRINKING_WATER_PROVISION), :lazy => true, :nullable => false, :default => 'Own well/pipe'
  
  property :sanitation_facilities, Enum.send('[]',*SANITATION_PROVISION), :lazy => true, :nullable => false, :default => 'Own toilet, septic tank'

  property :in_good_health, Boolean, :lazy => true, :nullable => false, :default => true

  property :any_illness_for_a_long_time, Boolean, :lazy => true, :nullable => false, :default => false

  property :expense_on_healthcare, Integer, :lazy => true, :nullable => true

  property :healthcare_being_provided, Text, :lazy => true, :nullable => true

  property :any_orphans, Boolean, :lazy => true, :nullable => false, :default => false

  property :orphan_details, Text, :lazy => true, :nullable => true

  #means of information
  property :get_newspaper, Boolean, :default => true, :lazy => true, :nullable => false
  property :listen_radio, Boolean, :default => false, :lazy => true, :nullable => false
  property :watch_tv, Boolean, :default => true, :lazy => true, :nullable => false

  property :have_computer_and_internet, Boolean, :default => false, :nullable => false, :lazy => true

  #electricity and communication 
  property :have_electricity, Boolean, :default => false, :nullable => false, :lazy => true

  property :have_landline, Boolean, :default => false, :nullable => false, :lazy => true

  property :have_cellphone, Boolean, :default => false, :nullable => false, :lazy => true

  property :monthly_family_income_and_sources, Enum.send('[]',*TOTAL_MONTHLY_INCOME), :nullable => false, :lazy => true, :default => 'Above 7000'

  #identification documents
  property :have_ration_card, Boolean, :default => false, :nullable => false, :lazy => true

  property :have_election_card, Boolean, :default => false, :nullable => false, :lazy => true

  property :have_pensioners_id_card, Boolean, :default => false, :nullable => false, :lazy => true

  #other details
  property :monthly_family_expenses, String, :length => 7, :lazy => true
  property :below_poverty_line, Boolean, :default => false, :nullable => false, :lazy => true
  property :years_of_residing_at_current_location, String, :length => 3, :lazy => true
  property :own_house, Boolean, :default => false, :nullable => false, :lazy => true
  property :family_owns_land, Boolean, :default => false, :nullable => false, :lazy => true

  #Should we give a default unit to this ? Should we allow the user to put it ?
  #how do we make these properties compulsory only in case of above being True
  property :area_of_owned_land, String, :length => 6, :lazy => true
  property :estimated_value_of_owned_land, String, :length => 7, :lazy => true

  validates_length :number_of_family_members, :max => 20
  validates_length :school_distance, :max => 200
  validates_length :phc_distance, :max => 500

  belongs_to :organization, :parent_key => [:org_guid], :child_key => [:parent_org_guid], :required => false
  property   :parent_org_guid, String, :nullable => true

  belongs_to :domain, :parent_key => [:domain_guid], :child_key => [:parent_domain_guid], :required => false
  property   :parent_domain_guid, String, :nullable => true

  has n, :loans
  has n, :payments
  has n, :insurance_policies
  has n, :attendances
  has n, :claims
  has n, :guarantors
  has n, :applicable_fees,    :child_key => [:applicable_id], :applicable_type => "Client"
  validates_length :account_number, :max => 20

  belongs_to :center
  belongs_to :client_group
  belongs_to :occupation, :nullable => true
  belongs_to :client_type
  belongs_to :created_by,        :child_key => [:created_by_user_id],         :model => 'User'
  belongs_to :created_by_staff,  :child_key => [:created_by_staff_member_id], :model => 'StaffMember'
  belongs_to :verified_by,       :child_key => [:verified_by_user_id],        :model => 'User'

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
  validates_present   :center
  validates_present   :date_joined
  validates_is_unique :reference
  validates_with_method  :verified_by_user_id,          :method => :verified_cannot_be_deleted, :if => Proc.new{|x| x.deleted_at != nil}
  validates_attachment_thumbnails :picture
  validates_with_method :date_joined, :method => :dates_make_sense
  validates_with_method :inactive_reason, :method => :cannot_have_inactive_reason_if_active

  def update_loan_cache
    loans.each{|l| l.update_loan_cache(true); l.save}
  end

  def self.from_csv(row, headers)
    if center_attr = row[headers[:center]].strip
      if center   = Center.first(:name => center_attr)
      elsif center   = Center.first(:code => center_attr)
      elsif /\d+/.match(center_attr)
        center   = Center.get(center_attr)
      end
    end
    raise ArgumentError("No center with code/id #{center_attr}") unless center
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
    client_type     = ClientType.first||ClientType.create(:type => "Standard")
    grt_date        = row[headers[:grt_date]] ? Date.parse(row[headers[:grt_date]]) : nil
    keys = [:reference, :name, :spouse_name, :date_of_birth, :address, :date_joined, :center, :grt_date, :created_by_staff, :group]
    missing_keys = keys - headers.keys
    raise ArgumentError.new("missing keys #{missing_keys.join(',')}") unless missing_keys.blank?
    hash = {:reference => row[headers[:reference]], :name => row[headers[:name]], :spouse_name => row[headers[:spouse_name]],
      :date_of_birth => Date.parse(row[headers[:date_of_birth]]), :address => row[headers[:address]], 
      :date_joined => row[headers[:date_joined]], :center => center, :grt_pass_date => grt_date, :created_by => User.first,
      :created_by_staff_member_id => StaffMember.first(:name => row[headers[:created_by_staff]]).id,
      :client_group => client_group, :client_type => client_type, :upload_id => row[headers[:upload_id]]}
    obj             = new(hash)
    [obj.save!, obj]
  end

  def self.search(q, per_page=10)
    if /^\d+$/.match(q)
      all(:conditions => {:id => q}, :limit => per_page)
    else
      all(:conditions => ["reference=? or name like ?", q, q+'%'], :limit => per_page)
    end
  end

  def pay_fees(amount, date, received_by, created_by)
    @errors = []
    fp = fees_payable_on(date)
    pay_order = fee_schedule.keys.sort.map{|d| fee_schedule[d].keys}.flatten
    pay_order.each do |k|
      if fees_payable_on(date).has_key?(k)
        pay = Payment.new(:amount => [fp[k], amount].min, :type => :fees, :received_on => date, :comment => k.name, :fee => k,
                          :received_by => received_by, :created_by => created_by, :client => self)        
        if pay.save_self
          amount -= pay.amount
          fp[k] -= pay.amount
        else
          @errors << pay.errors
        end
      end
    end
    @errors.blank? ? true : @errors
  end

  def self.flags
    FLAGS
  end

  def make_center_leader
    return "Already is center leader for #{center.name}" if CenterLeader.first(:client => self, :center => self.center)
    CenterLeader.all(:center => center, :current => true).each{|cl|
      cl.current = false
      cl.date_deassigned = Date.today
      cl.save
    }
    CenterLeader.create(:center => center, :client => self, :current => true, :date_assigned => Date.today)
  end

  def check_client_deceased
    if not self.active and not self.inactive_reason.blank? and [:death_of_client, :death_of_spouse].include?(self.inactive_reason.to_sym)
      loans.each do |loan|
        if (loan.status==:outstanding or loan.status==:disbursed or loan.status==:claim_settlement) and self.claims.length>0 and claim=self.claims.last
          if claim.stop_further_installments
            last_payment_date = loan.payments.aggregate(:received_on.max)
            #set date of stopping payments/claim settlement one ahead of date of last payment
            if last_payment_date and (last_payment_date > claim.date_of_death) 
              loan.under_claim_settlement = last_payment_date + 1
            elsif claim.date_of_death
              loan.under_claim_settlement = claim.date_of_death
            else
              loan.under_claim_settlement = Date.today
            end
            loan.save
          end
        end
      end
    end
  end

  private
  def convert_blank_to_nil
    self.attributes.each{|k, v|
      if v.is_a?(String) and v.empty? and self.class.send(k).type==Integer
        self.send("#{k}=", nil)
      end
    }
    self.type_of_account = 0 if self.type_of_account == nil
    self.occupation = nil if self.occupation.blank?
    #convert other occupations also
    self.family_6_occupation = nil if self.family_6_occupation.blank?
    self.family_5_occupation = nil if self.family_5_occupation.blank?
    self.family_4_occupation = nil if self.family_4_occupation.blank?
    self.family_3_occupation = nil if self.family_3_occupation.blank?
    self.family_2_occupation = nil if self.family_2_occupation.blank?
    self.family_1_occupation = nil if self.family_1_occupation.blank?
    
    self.type_of_account = '' if self.type_of_account.nil? or self.type_of_account=="0"
  end

  def add_created_by_staff_member
    if self.center and self.new?
      self.created_by_staff_member_id = self.center.manager_staff_id
    end
  end

  def dates_make_sense
    return true if not grt_pass_date or not date_joined 
    return [false, "Client cannot join this center before the center was created"] if center and center.creation_date and center.creation_date > date_joined
    return [false, "GRT Pass Date cannot be before Date Joined"]  if grt_pass_date < date_joined
    return [false, "Client cannot die before he became a client"] if deceased_on and (deceased_on < date_joined or deceased_on < grt_pass_date)
    true
  end

  def verified_cannot_be_deleted
    return true unless verified_by_user_id
    throw :halt
    [false, "Verified client. Cannot be deleted"]
  end

  def self.death_cases(obj, from_date, to_date)
     d2 = to_date.strftime('%Y-%m-%d')
    if obj.class == Branch 
      from  = "branches b, centers c, clients cl, claims cm"
      where = %Q{
                cl.active = false AND cl.inactive_reason IN (2,3) AND cl.id = cm.client_id AND cm.claim_submission_date >= #{from_date.strftime('%Y-%m-%d')} AND cm.claim_submission_date <= 'd2' AND cl.center_id = c.id AND c.branch_id = b.id  AND b.id = #{obj.id}   
                };
      
    elsif obj.class == Center
      from  = "centers c, clients cl, claims cm"     
      where = %Q{
               cl.active = false AND cl.inactive_reason IN (2,3) AND cl.id = cm.client_id AND cm.claim_submission_date >= #{from_date.strftime('%Y-%m-%d')} AND cm.claim_submission_date <= 'd2' AND cl.center_id = c.id AND c.id = #{obj.id}   
                };
      
    elsif obj.class == StaffMember
      # created_by_staff_member_id
      from =  "clients cl, claims cm, staff_members sm"      
      where = %Q{
                cl.active = false AND cl.inactive_reason IN (2,3)  AND cl.id = cm.client_id AND cm.claim_submission_date >= #{from_date.strftime('%Y-%m-%d')} AND cm.claim_submission_date <= 'd2' AND cl.created_by_staff_member_id = sm.id AND sm.id = #{obj.id}    
                };
      
    end
    repository.adapter.query(%Q{
                             SELECT COUNT(cl.id)
                             FROM #{from}
                             WHERE #{where}
                           })
  end
  
   def self.pending_death_cases(obj,from_date, to_date) 
     if obj.class == Branch
       repository.adapter.query(%Q{
                                SELECT COUNT(cl.id)
                                FROM branches b, centers c, clients cl, claims cm
                                WHERE cl.active = false AND cl.inactive_reason IN (2,3)
                                AND cl.center_id = c.id AND c.branch_id = b.id 
                                AND b.id = #{obj.id} AND cl.id NOT IN (SELECT client_id FROM claims)     
                               })
       
     elsif obj.class == Center      
       repository.adapter.query(%Q{
                                SELECT COUNT(cl.id)
                                FROM centers c, clients cl, claims cm 
                                WHERE cl.active = false AND cl.inactive_reason IN (2,3)
                                AND cl.center_id = c.id AND c.id = #{obj.id} AND cl.id
                                NOT IN (SELECT client_id FROM claims )   
                              })

     elsif obj.class == StaffMember
       repository.adapter.query(%Q{
                                SELECT COUNT(cl.id)
                                FROM clients cl, claims cm, staff_members sm 
                                WHERE cl.active = false AND cl.inactive_reason IN (2,3)
                                AND cl.created_by_staff_member_id = sm.id AND sm.id = #{obj.id} AND cl.id
                                NOT IN (SELECT client_id FROM claims )
                                })
     end
   end
   
   def cannot_have_inactive_reason_if_active
     return [false, "cannot have a inactive reason if active"] if self.active and not inactive_reason.blank?
     return true
   end

 end
