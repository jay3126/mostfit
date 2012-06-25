class User
  include DataMapper::Resource
  include Constants::Properties
  include Constants::User

  before :destroy, :prevent_destroying_admin
  after  :save,    :set_staff_member

  property :id,           Serial
  property :login,        String, :nullable => false
  property :created_at,   DateTime              
  property :updated_at,   DateTime
  property :password_changed_at, DateTime, :default => Time.now, :nullable => false
  property :active,       Boolean, :default => true, :nullable => false
  property :preferred_locale,        String


  # it gets                                   
  #   - :password and :password_confirmation accessors
  #   - :crypted_password and :salt db columns        
  # from the mixin.
  validates_present :login
  validates_format :login, :with => /^[A-Za-z0-9_]+$/
  validates_length :login, :min => 3
  validates_is_unique :login
  validates_length :password, :min => 6, :if => Proc.new{|u| not u.password.nil?}
  
  has 1, :staff_member
  has 1, :funder

  has n, :payments_created, :child_key => [:created_by_user_id], :model => 'Payment'
  has n, :payments_deleted, :child_key => [:deleted_by_user_id], :model => 'Payment'
  has n, :audit_trail, :model => 'AuditTrail'
  
  def set_staff_member
    if self.staff_member
      staff          = StaffMember.get(self.staff_member)
      staff.user_id  = self.id
      staff.save
    end
  end

  def get_user_role
    if self.staff_member
      staff_member_designation = self.staff_member.designation
      if staff_member_designation
        return staff_member_designation.role_class
      end
    end
  end

  def self.roles
    roles = []
    Constants::User::ROLE_CLASSES.each_with_index{|v, idx|
      roles << [v, v.to_s.gsub('_', ' ').capitalize]
    }
    roles
  end

  def name
    login
  end

  def admin?
     get_user_role == :administrator
  end
  
  def crud_rights
    Misfit::Config.crud_rights[role]
  end

  def access_rights
    Misfit::Config.access_rights[role]
  end

  def to_s
    login
  end
  
  def password_too_old
    if self.password_changed_at and mfi = Mfi.first and mfi.password_change_in and mfi.password_change_in.to_i>0
      return true if Date.today - self.password_changed_at > mfi.password_change_in
    end
  end

  def method_missing(name, params)
    if x = /can_\w+\?/.match(name.to_s)
      return true if role == :administrator
      function = x[0].split("_")[1].gsub("?","").to_sym
      puts function
      raise NoMethodError if not ([:edit, :update, :create, :new, :delete, :destroy].include?(function))
      model = params
      r = (crud_rights[function] or crud_rights[:all])
      return false if r.nil?
      r.include?(model)
    else
      raise NoMethodError
    end
  end

 private
  def prevent_destroying_admin
    if id == 1
      errors.add(:login, "Cannot delete #{login} (the admin user).")
      throw :halt
    end                                                             
  end
end
