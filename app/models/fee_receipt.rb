class FeeReceipt
  include DataMapper::Resource
  include Constants::Properties
  include Constants::Fee
  include Constants::Transaction

  property :id,           Serial
  property :fee_amount,   *MONEY_AMOUNT_NON_ZERO
  property :currency,     *CURRENCY
  property :effective_on, *DATE_NOT_NULL
  property :fee_applied_on_type, Enum.send('[]', *FEE_APPLIED_ON_TYPES), :nullable => false
  property :fee_applied_on_type_id, *INTEGER_NOT_NULL
  property :by_counterparty_type, Enum.send('[]', *COUNTERPARTIES), :nullable => false
  property :by_counterparty_id,   *INTEGER_NOT_NULL
  property :performed_at, *INTEGER_NOT_NULL
  property :accounted_at, *INTEGER_NOT_NULL
  property :performed_by, *INTEGER_NOT_NULL
  property :recorded_by,  *INTEGER_NOT_NULL
  property :created_at,   *CREATED_AT

  belongs_to :fee_instance, :nullable => true
  belongs_to :simple_fee_product

=begin
A fee receipt can be for an ad-hoc fee or a scheduled fee
The fee must record the fee amounts, who paid it, against which (loan) product, for which
fee product, and when

=end

  def performed_by_staff; StaffMember.get self.performed_by; end;

  def money_amounts; [ :fee_amount ]; end
  
  def fee_money_amount; to_money_amount(:fee_amount); end

  def self.record_ad_hoc_fee(fee_money_amount, fee_product, effective_on, fee_recorded_on_type, performed_by_id, recorded_by_id)
    Validators::Arguments.not_nil?(fee_money_amount, fee_product, effective_on, fee_recorded_on_type, performed_by_id, recorded_by_id)

    performed_at = nil
    accounted_at = nil
    if (fee_recorded_on_type.is_a?(Lending))
      performed_at = fee_recorded_on_type.administered_at(effective_on)
      accounted_at = fee_recorded_on_type.accounted_at(effective_on)
    else
      raise Errors::BusinessValidationError, "Ad hoc fees can currently only be recorded on loans"
    end
    raise Errors::InvalidConfigurationError, "Locations could not be determined" unless (performed_at and accounted_at)

    fee_receipt_values = {}
    fee_receipt_values[:performed_at] = performed_at.id
    fee_receipt_values[:accounted_at] = accounted_at.id
    fee_receipt_values[:simple_fee_product] = fee_product

    fee_applied_on_type, fee_applied_on_type_id = Resolver.resolve_fee_applied_on(fee_recorded_on_type)
    fee_receipt_values[:fee_applied_on_type]    = fee_applied_on_type
    fee_receipt_values[:fee_applied_on_type_id] = fee_applied_on_type_id

    for_counterparty = fee_recorded_on_type.counterparty
    by_counterparty_type, by_counterparty_id = Resolver.resolve_counterparty(for_counterparty)
    fee_receipt_values[:by_counterparty_type] = by_counterparty_type
    fee_receipt_values[:by_counterparty_id]   = by_counterparty_id

    fee_receipt_values[:fee_amount]   = fee_money_amount.amount
    fee_receipt_values[:currency]     = fee_money_amount.currency
    fee_receipt_values[:effective_on] = effective_on
    fee_receipt_values[:performed_by] = performed_by_id
    fee_receipt_values[:recorded_by]  = recorded_by_id

    fee_receipt = create(fee_receipt_values)
    raise Errors::DataError, fee_receipt.errors.first.first unless fee_receipt.saved?
    fee_receipt
  end

  def self.record_fee_receipt(fee_instance, fee_money_amount, effective_on, performed_by_id, recorded_by_id)
    Validators::Arguments.not_nil?(fee_instance, fee_money_amount, effective_on, performed_by_id, recorded_by_id)
    fee_receipt_values = {}
    
    fee_receipt_values[:fee_instance] = fee_instance
    fee_receipt_values[:simple_fee_product]  = fee_instance.simple_fee_product
    
    performed_at = fee_instance.administered_at
    accounted_at = fee_instance.accounted_at
    fee_receipt_values[:performed_at] = performed_at
    fee_receipt_values[:accounted_at] = accounted_at

    fee_applied_on_type    = fee_instance.fee_applied_on_type
    fee_applied_on_type_id = fee_instance.fee_applied_on_type_id

    fee_receipt_values[:fee_applied_on_type]    = fee_applied_on_type
    fee_receipt_values[:fee_applied_on_type_id] = fee_applied_on_type_id

    by_counterparty_type = fee_instance.by_counterparty_type
    by_counterparty_id   = fee_instance.by_counterparty_id
    fee_receipt_values[:by_counterparty_type] = by_counterparty_type
    fee_receipt_values[:by_counterparty_id]   = by_counterparty_id

    fee_receipt_values[:fee_amount]   = fee_money_amount.amount
    fee_receipt_values[:currency]     = fee_money_amount.currency
    fee_receipt_values[:effective_on] = effective_on
    fee_receipt_values[:performed_by] = performed_by_id
    fee_receipt_values[:recorded_by]  = recorded_by_id

    fee_receipt = create(fee_receipt_values)
    raise Errors::DataError, fee_receipt.errors.first.first unless fee_receipt.saved?
    fee_receipt
  end

end