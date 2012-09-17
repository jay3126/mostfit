class TimedAmount
  include DataMapper::Resource
  include Constants::Properties, Constants::Transaction

  property :id,                  Serial
  property :fee_only_amount,     *MONEY_AMOUNT_NULL
  property :tax_only_amount,     *MONEY_AMOUNT_NULL
  property :amount_type,         Enum.send('[]', *FEE_AMOUNT_TYPE), :nullable => false, :default => FIX_AMOUNT
  property :fee_only_percentage, Float, :nullable => true
  property :tax_only_percentage, Float, :nullable => true
  property :currency,            *CURRENCY
  property :effective_on,        *DATE_NOT_NULL
  property :created_at,          *CREATED_AT

  belongs_to :simple_fee_product, :nullable => true

  def money_amounts; [:fee_only_amount, :tax_only_amount]; end

  def fee_money_amount(amount = MoneyManager.default_zero_money)
    if self.amount_type == PERCENTAGE_AMOUNT
      fee_percentage   = self.fee_only_percentage.blank? ? 0 : self.fee_only_percentage
      fee_amount       = (fee_percentage.to_f/100) * amount.amount
      fee_money_amount = MoneyManager.get_money_instance_least_terms(fee_amount.to_i)
    elsif self.amount_type == FIX_AMOUNT
      fee_money_amount = to_money_amount(:fee_only_amount);
    end
    fee_money_amount
  end

  def tax_money_amount(amount = MoneyManager.default_zero_money)
    if self.amount_type == PERCENTAGE_AMOUNT
      tax_percentage   = self.tax_only_percentage.blank? ? 0 : self.tax_only_percentage
      tax_amount       = (tax_percentage.to_f/100) * amount.amount
      tax_money_amount = MoneyManager.get_money_instance_least_terms(tax_amount.to_i)
    elsif self.amount_type == FIX_AMOUNT
      tax_money_amount = to_money_amount(:tax_only_amount);
    end
    tax_money_amount
  end
  
  def total_money_amount(amount = MoneyManager.default_zero_money)
    fee_money_amount(amount) + tax_money_amount(amount)
  end
  
end
