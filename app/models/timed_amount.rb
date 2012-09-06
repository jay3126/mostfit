class TimedAmount
  include DataMapper::Resource
  include Constants::Properties, Constants::Transaction

  property :id,              Serial
  property :fee_only_amount, *MONEY_AMOUNT_NULL
  property :tax_only_amount, *MONEY_AMOUNT_NULL
  property :amount_type,     Enum.send('[]', *FEE_AMOUNT_TYPE), :nullable => false, :default => FIX_AMOUNT
  property :percentage,      Float
  property :currency,        *CURRENCY
  property :effective_on,    *DATE_NOT_NULL
  property :created_at,      *CREATED_AT

  belongs_to :simple_fee_product, :nullable => true

  def money_amounts; [:fee_only_amount, :tax_only_amount]; end

  def fee_money_amount; to_money_amount(:fee_only_amount); end
  def tax_money_amount; to_money_amount(:tax_only_amount); end
  def total_money_amount; fee_money_amount + tax_money_amount; end
  
end
