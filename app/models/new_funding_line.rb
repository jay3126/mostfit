class NewFundingLine
  include DataMapper::Resource
  include Constants::Properties

  property :id,             Serial
  property :amount,         *MONEY_AMOUNT
  property :currency,       *CURRENCY
  property :sanction_date,  *DATE
  property :created_by,     Integer
  property :created_at,     DateTime, :nullable => false, :default => DateTime.now

  belongs_to :new_funder

  def money_amounts; [:amount]; end
  def funding_line_money_amount; to_money_amount(:amount); end

end