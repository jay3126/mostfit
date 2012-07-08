class FeeReceipt
  include DataMapper::Resource
  include Constants::Properties
  include Constants::Fee

  property :id,           Serial
  property :fee_amount,   *MONEY_AMOUNT_NON_ZERO
  property :currency,     *CURRENCY
  property :effective_on, *DATE_NOT_NULL
  property :fee_applied_on_type, Enum.send('[]', *FEE_APPLIED_ON_TYPES), :nullable => false
  property :fee_applied_on_type_id, *INTEGER_NOT_NULL
  property :performed_at, *INTEGER_NOT_NULL
  property :accounted_at, *INTEGER_NOT_NULL
  property :performed_by, *INTEGER_NOT_NULL
  property :recorded_by,  *INTEGER_NOT_NULL
  property :created_at,   *CREATED_AT

  belongs_to :fee_instance

  def performed_by_staff; StaffMember.get self.performed_at; end;

  def money_amounts; [ :fee_amount ]; end
  
  def fee_money_amount; to_money_amount(:fee_amount); end

  def self.record_fee_receipt(fee_instance, fee_money_amount, effective_on, performed_by_id, recorded_by_id)
    Validators::Arguments.not_nil?(fee_instance, fee_money_amount, effective_on, performed_by_id, recorded_by_id)
    fee_receipt_values = {}
    
    fee_receipt_values[:fee_instance] = fee_instance
    performed_at = fee_instance.administered_at
    accounted_at = fee_instance.accounted_at
    fee_receipt_values[:performed_at] = performed_at
    fee_receipt_values[:accounted_at] = accounted_at

    fee_applied_on_type    = fee_instance.fee_applied_on_type
    fee_applied_on_type_id = fee_instance.fee_applied_on_type_id
    
    fee_receipt_values[:fee_applied_on_type]    = fee_applied_on_type
    fee_receipt_values[:fee_applied_on_type_id] = fee_applied_on_type_id
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