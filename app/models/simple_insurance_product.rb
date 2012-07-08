class SimpleInsuranceProduct
  include DataMapper::Resource
  include Constants::Properties, Constants::Insurance

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

end
