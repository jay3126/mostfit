class Encumberance
  include DataMapper::Resource
  include Constants::Properties, Constants::Money
  
  property :id,             Serial
  property :name,           String, :nullable => false, :length => 255, :unique => true
  property :effective_on,   *DATE_NOT_NULL
  property :assigned_value, *MONEY_AMOUNT
  property :currency,       *CURRENCY
  property :performed_by,   Integer
  property :recorded_by,    Integer
  property :created_at,     *CREATED_AT

  has n, :third_parties, :through => Resource

  def money_amounts; [:assigned_value]; end
  
  def assigned_value_money_amount; to_money_amount(:assigned_value); end

  def to_s
    "Encumberance: #{name} effective on #{effective_on}"
  end

end
