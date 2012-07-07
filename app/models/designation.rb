class Designation
  include DataMapper::Resource
  include Constants::Properties, Constants::User
  include Identified
  
  property :id,         Serial
  property :name,       String, :nullable => false, :unique => true
  property :role_class, Enum.send('[]', *ROLE_CLASSES), :nullable => false
  property :created_at, *CREATED_AT

  belongs_to :location_level
  has n, :staff_members

  def is_supervisor?
    self.role_class == SUPERVISOR
  end

  def is_executive?
    self.role_class == EXECUTIVE
  end

  def is_support?
    self.role_class == SUPPORT
  end

  def is_finops?
    self.role_class == FINOPS
  end

  def is_administrator?
    self.role_class == ADMINISTRATOR
  end

end
