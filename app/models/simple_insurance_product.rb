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
  belongs_to :upload, :nullable => true

  def total_premium_money_amount(on_date)
    self.premium ? self.premium.effective_total_amount(on_date) : nil
  end

  #this function is for upload functionality.
  def self.from_csv(row, headers)
    fee_product = SimpleFeeProduct.first(:name => row[headers[:fee_product]])
    raise ArgumentError, "Fee Product (#{row[headers[:fee_product]]}) does not exist" if fee_product.blank?
    name = row[headers[:name]]
    insurance_type = row[headers[:insurance_type]].downcase.to_sym
    insurance_for = row[headers[:insurance_for]].downcase.to_sym
    created_on = Date.parse(row[headers[:created_on]])

    obj = SimpleInsuranceProduct.new(:name => name, :insured_type => insurance_type, :insurance_for => insurance_for, :created_on => created_on)

    if obj.save
      fee_product.update(:simple_insurance_product_id => obj.id) unless fee_product.blank?
      [true, obj]
    else
      [false, obj]
    end
  end

  def get_premium_fee_amount(lending, on_date)
    fee_timed_amount = self.premium.effective_timed_amount(on_date)
    if fee_timed_amount.amount_type == PERCENTAGE_AMOUNT && !lending.blank?
      loan_amount      = lending.to_money[:disbursed_amount]||lending.to_money[:applied_amount]
      fee_money_amount = fee_timed_amount.total_money_amount(loan_amount)
    elsif fee_timed_amount.amount_type == FIX_AMOUNT
      fee_money_amount = fee_timed_amount.total_money_amount
    end
    fee_money_amount.blank? ? MoneyManager.default_zero_money : fee_money_amount
  end

end
