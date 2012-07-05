class FeeInstance
  include DataMapper::Resource
  include Constants::Properties
  include Constants::Fee

  property :id,                     Serial
  property :fee_applied_on_type,    Enum.send('[]', *FEE_APPLIED_ON_TYPES), :nullable => false
  property :fee_applied_on_type_id, *INTEGER_NOT_NULL
  property :administered_at,        *INTEGER_NOT_NULL
  property :accounted_at,           *INTEGER_NOT_NULL
  property :applied_on,             *DATE_NOT_NULL
  property :created_at,             *CREATED_AT

  belongs_to :simple_fee_product
  has 1, :fee_receipt

  def administered_at_location; BizLocation.get(self.administered_at); end
  def accounted_at_location; BizLocation.get(self.accounted_at); end

  def effective_total_amount(on_date)
    self.simple_fee_product.effective_total_amount(on_date)
  end

  def self.register_fee_instance(fee_product, fee_on_type, administered_at_id, accounted_at_id, applied_on)
    Validators::Arguments.not_nil?(fee_product, fee_on_type, administered_at_id, accounted_at_id, applied_on)
    fee_instance = {}
    fee_applied_on_type, fee_applied_on_type_id = Resolver.resolve_fee_applied_on(fee_on_type)

    fee_instance[:fee_applied_on_type] = fee_applied_on_type
    fee_instance[:fee_applied_on_type_id] = fee_applied_on_type_id
    fee_instance[:administered_at] = administered_at_id
    fee_instance[:accounted_at]    = accounted_at_id
    fee_instance[:applied_on]      = applied_on
    fee_instance[:simple_fee_product] = fee_product
    fee = create(fee_instance)
    raise Errors::DataError, fee.errors.first.first unless fee.saved?
    fee
  end

  def self.all_unpaid_fees(search_options = {})
    (all(search_options)).reject {|fee_instance| fee_instance.is_collected?}
  end

  def is_collected?
    not (self.fee_receipt.nil?)
  end

  def self.get_all_fees_for_instance(fee_on_type)
    fee_applied_on_type, fee_applied_on_type_id = Resolver.resolve_fee_applied_on(fee_on_type)
    all(:fee_applied_on_type => fee_applied_on_type, :fee_applied_on_type_id => fee_applied_on_type_id)
  end
  
  def self.get_unpaid_fees_for_instance(fee_on_type)
    (get_all_fees_for_instance(fee_on_type)).reject {|fee_instance| fee_instance.is_collected?}
  end

end
