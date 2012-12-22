class SimpleFeeProduct
  include DataMapper::Resource
  include Constants::Properties, Constants::Transaction

  property :id,                  Serial
  property :name,                *UNIQUE_NAME
  property :fee_charged_on_type, Enum.send('[]', *FEE_CHARGED_ON_TYPES), :nullable => false
  property :created_on,          *DATE_NOT_NULL
  property :created_at,          *CREATED_AT

  has n, :timed_amounts
  has n, :fee_administrations
  belongs_to :simple_insurance_product, :nullable => true
  belongs_to :lending_product_for_fee, 'LendingProduct', :nullable => true, :parent_key => [:id], :child_key => [:loan_fee_id]
  belongs_to :lending_product_for_penalty, 'LendingProduct', :nullable => true, :parent_key => [:id], :child_key => [:loan_preclosure_penalty_id]

  has n, :fee_instances
  belongs_to :upload, :nullable => true

  #method for upload functionality.
  def self.from_csv(row, headers)
    obj = new(:name => row[headers[:name]], :fee_charged_on_type => row[headers[:fee_type]], :created_on => row[headers[:creation_date]],
              :upload_id => row[headers[:upload_id]])
    if obj.save
      money_amount = MoneyManager.get_money_instance(row[headers[:fee_amount]])
      money_tax    = MoneyManager.get_money_instance(row[headers[:fee_tax]])
      amount_type  = Constants::Transaction::FIX_AMOUNT
      timed_amount = TimedAmount.new(:simple_fee_product_id => obj.id, :fee_only_amount => money_amount.amount,
                                     :tax_only_amount => money_tax.amount, :effective_on => row[headers[:effective_date]],
                                     :currency => money_amount.currency, :amount_type => amount_type)
      timed_amount.save
      [true, obj]
    else
      [false, obj]
    end
  end
 
  def effective_timed_amount(on_date = Date.today)
    self.timed_amounts.first(:effective_on.lte => on_date, :order => [:effective_on.desc])
  end

  def effective_fee_only_amount(on_date = Date.today, amount = MoneyManager.default_zero_money)
    timed_amount = effective_timed_amount(on_date)
    timed_amount ? timed_amount.fee_money_amount(amount) : MoneyManager.default_zero_money
  end

  def effective_tax_only_amount(on_date = Date.today, amount = MoneyManager.default_zero_money)
    timed_amount = effective_timed_amount(on_date)
    timed_amount ? timed_amount.tax_money_amount(amount) : MoneyManager.default_zero_money
  end

  def effective_total_amount(on_date = Date.today, amount = MoneyManager.default_zero_money)
    timed_amount = effective_timed_amount(on_date)
    timed_amount ? timed_amount.total_money_amount(amount) : MoneyManager.default_zero_money
  end

  def self.get_applicable_fee_products_on_loan_product(loan_product_id)
    applicable_fee_products = {}
    loan_fee = first(:loan_fee_id => loan_product_id)
    applicable_fee_products[Constants::Transaction::FEE_CHARGED_ON_LOAN] = loan_fee if loan_fee

    penalty_fee = first(:loan_preclosure_penalty_id => loan_product_id)
    applicable_fee_products[Constants::Transaction::PRECLOSURE_PENALTY_ON_LOAN] = penalty_fee if penalty_fee
    
    applicable_fee_products
  end

  def self.get_applicable_loan_fee_product_on_loan_product(loan_product_id)
    fee_products = get_applicable_fee_products_on_loan_product(loan_product_id)
    fee_products ? fee_products[Constants::Transaction::FEE_CHARGED_ON_LOAN] : nil
  end

  def self.get_applicable_preclosure_penalty(loan_product_id)
    fee_products = get_applicable_fee_products_on_loan_product(loan_product_id)
    fee_products ? fee_products[Constants::Transaction::PRECLOSURE_PENALTY_ON_LOAN] : nil
  end

  def self.get_applicable_premium_on_insurance_product(insurance_product_id)
    applicable_premium_products = {}
    premium = first(:simple_insurance_product_id => insurance_product_id)
    applicable_premium_products[Constants::Transaction::PREMIUM_COLLECTED_ON_INSURANCE] = premium if premium
    applicable_premium_products
  end

  def get_fee_instance_on_loan(loan_id)
    self.fee_instances.first(:fee_applied_on_type => Constants::Fee::FEE_ON_LOAN, :fee_applied_on_type_id => loan_id)
  end

end
