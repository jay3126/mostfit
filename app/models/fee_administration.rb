class FeeAdministration

  include DataMapper::Resource
  include Constants::Properties, Constants::Loan

  property :id,                    Serial
  property :product_type,          String
  property :product_id,            *INTEGER_NOT_NULL
  property :effective_on,          *DATE_NOT_NULL
  property :performed_by,          *INTEGER_NOT_NULL
  property :recorded_by,           *INTEGER_NOT_NULL
  property :created_at,            *CREATED_AT

  belongs_to :simple_fee_product

  def self.fee_setup(fee_id, product_type, product_id, on_date, staff_id, user_id)

    fee_admin = self.new
    fee_admin[:simple_fee_product_id] = fee_id
    fee_admin[:product_type]          = product_type.humanize
    fee_admin[:product_id]            = product_id
    fee_admin[:effective_on]          = on_date
    fee_admin[:performed_by]          = staff_id
    fee_admin[:recorded_by]           = user_id
    fee_admin.save
  end

  def self.get_fee_products(on_product, on_date = Date.today)
    search                    = {}
    search[:product_type]     = on_product.class.to_s
    search[:product_id]       = on_product.id
    search[:effective_on.lte] = on_date
    fee_admins                = all(search)
    fee_admins.blank? ? [] : fee_admins.map(&:simple_fee_product)
  end

  def self.get_lending_fee_products(on_product, on_date = Date.today)
    get_fee_products(on_product, on_date).select{|fee| fee.fee_charged_on_type==Constants::Transaction::FEE_CHARGED_ON_LOAN}
  end

  def self.get_preclosure_penalty_fee_products(on_product, on_date = Date.today)
    get_fee_products(on_product, on_date).select{|fee| fee.fee_charged_on_type==Constants::Transaction::PRECLOSURE_PENALTY_ON_LOAN}
  end

  def self.save_fee_products
    fee_products = SimpleFeeProduct.all
    user = User.first
    user_id = user.id
    staff_id = user.staff_member.id
    fee_products.each do |fee_product|
      if !fee_product.loan_fee_id.blank?
        on_date = LendingProduct.get(fee_product.loan_fee_id).created_at
        fee_setup(fee_product.id, 'LendingProduct', fee_product.loan_fee_id, on_date, staff_id, user_id)
      elsif !fee_product.simple_insurance_product_id.blank?
        on_date = SimpleInsuranceProduct.get(fee_product.simple_insurance_product_id).created_at
        fee_setup(fee_product.id, 'SimpleInsuranceProduct', fee_product.simple_insurance_product_id, on_date, staff_id, user_id)
      end
    end
  end
end