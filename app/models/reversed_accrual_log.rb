class ReversedAccrualLog
  include DataMapper::Resource
  include Constants::Properties
  
  property :id,                              Serial
  property :accrual_transaction_id,          *INTEGER_NOT_NULL
  property :reversal_accrual_transaction_id, *INTEGER_NOT_NULL
  property :created_at,                      *CREATED_AT

  def self.record_reversed_accrual_log(accrual_transaction, reversal_accrual_transaction)
    log = create(:accrual_transaction_id => accrual_transaction.id, :reversal_accrual_transaction_id => reversal_accrual_transaction.id)
    raise Errors::DataError, log.errors.first.first unless log.saved?
    log
  end

  def self.reversal_for_accrual(accrual_transaction_id)
    first(:accrual_transaction_id => accrual_transaction_id)
  end

end
