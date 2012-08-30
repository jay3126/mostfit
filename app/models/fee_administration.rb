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
end