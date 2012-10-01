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
  def created_on; self.effective_on; end

  def to_s
    "Encumberance: #{name} effective on #{effective_on}"
  end

  def self.create_encumberance(name, effective_on, assigned_value_money_amount)
    new_encumberance = {}
    new_encumberance[:name] = name
    new_encumberance[:effective_on] = effective_on
    new_encumberance[:assigned_value] = assigned_value_money_amount.amount
    new_encumberance[:currency]       = assigned_value_money_amount.currency
    encumberance = create(new_encumberance)
    raise Errors::DataError, encumberance.errors.first.first unless encumberance.saved?
    encumberance
  end

end