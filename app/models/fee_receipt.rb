class FeeReceipt
  include DataMapper::Resource
  include Constants::Properties
  include Constants::Fee

  property :id,           Serial
  property :fee_amount,   *MONEY_AMOUNT_NON_ZERO
  property :currency,     *CURRENCY
  property :fee_applied_on_type, Enum.send('[]', *FEE_APPLIED_ON_TYPES), :nullable => false
  property :fee_applied_on_type_id, *INTEGER_NOT_NULL
  property :performed_at, *INTEGER_NOT_NULL
  property :accounted_at, *INTEGER_NOT_NULL
  property :performed_by, *INTEGER_NOT_NULL
  property :recorded_by,  *INTEGER_NOT_NULL
  property :created_at,   *CREATED_AT

  belongs_to :fee_instance

end
