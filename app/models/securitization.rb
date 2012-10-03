class Securitization
  include DataMapper::Resource
  include Constants::Properties
  
  property :id,           Serial
  property :name,         String, :nullable => false, :length => 255,:unique=>true
  property :effective_on, *DATE_NOT_NULL
  property :created_at,   *CREATED_AT

  has n,:third_parties, :through => Resource

  def created_on; self.effective_on; end

  def to_s
    "<b>Securitization:</b> #{name} <b>Effective On:</b> #{effective_on}"
  end

end