class TimedAmount
  include DataMapper::Resource
  include Constants::Properties, Constants::Transaction

  property :id,              Serial
  property :fee_only_amount, *MONEY_AMOUNT_NON_ZERO
  property :tax_only_amount, *MONEY_AMOUNT
  property :currency,        *CURRENCY
  property :effective_on,    *DATE_NOT_NULL
  property :created_at,      *CREATED_AT

  belongs_to :simple_fee_product

  def money_amounts; [:fee_only_amount, :tax_only_amount]; end

  def fee_money_amount; to_money_amount(:fee_only_amount); end
  def tax_money_amount; to_money_amount(:tax_only_amount); end
  def total_money_amount; fee_money_amount + tax_money_amount; end
  
end
