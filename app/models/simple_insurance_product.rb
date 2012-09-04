class SimpleInsuranceProduct
  include DataMapper::Resource
  include Constants::Properties, Constants::Insurance, Constants::Transaction

  property :id,            Serial
  property :name,          *UNIQUE_NAME
  property :insured_type,  Enum.send('[]', *INSURANCE_TYPES)
  property :insurance_for, Enum.send('[]', *INSURED_PERSON_RELATIONSHIPS)
  property :created_on,    *DATE_NOT_NULL
  property :created_at,    *CREATED_AT

  belongs_to :lending_product, :nullable => true
  has 1, :premium, 'SimpleFeeProduct'
  has n, :simple_insurance_policies

  def total_premium_money_amount(on_date)
    self.premium ? self.premium.effective_total_amount(on_date) : nil
  end

  def get_premium_fee_amount(lending, on_date)
    fee_timed_amount = self.premium.effective_timed_amount(on_date)
    if fee_timed_amount.amount_type == PERCENTAGE_AMOUNT && !lending.blank?
      loan_amount      = lending.to_money[:disbursed_amount]||lending.to_money[:applied_amount]
      percentage       = fee_timed_amount.percentage.to_f
      fee_amount       = (percentage/100) * loan_amount.amount
      fee_money_amount = MoneyManager.get_money_instance_least_terms(fee_amount.to_i)
    elsif fee_timed_amount.amount_type == FIX_AMOUNT
      fee_money_amount = fee_timed_amount.total_money_amount
    end
    fee_money_amount.blank? ? MoneyManager.default_zero_money : fee_money_amount
  end

end
