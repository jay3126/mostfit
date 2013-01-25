class LoanPayment
  include DataMapper::Resource
  include Constants::Properties, Constants::LoanAmounts

  property :id,            Serial
  property LOAN_DISBURSED, *MONEY_AMOUNT
  property :currency,      *CURRENCY
  property :effective_on,  *DATE_NOT_NULL
  property :created_at,    *CREATED_AT

  def money_amounts; [LOAN_DISBURSED]; end

  belongs_to :lending
  belongs_to :payment_transaction, :nullable => true

  # Records a payment (typically a loan disbursement) on the loan
  def self.record_loan_payment(payment_transaction, loan_disbursed_amount, on_loan, effective_on)
    Validators::Arguments.not_nil?(loan_disbursed_amount, on_loan, effective_on)
    payment                       = {}
    payment[LOAN_DISBURSED]       = loan_disbursed_amount.amount
    payment[:currency]            = loan_disbursed_amount.currency
    payment[:effective_on]        = effective_on
    payment[:lending]             = on_loan
    payment[:payment_transaction] = payment_transaction
    recorded_payment              = create(payment)
    raise Errors::DataError, "Payment was not saved on loan" unless recorded_payment.saved?
    recorded_payment
  end

  # Add up loan payments on or before the specified date
  def self.sum_till_date(on_date = Date.today)
    matching_date = {}
    matching_date[:effective_on.lte] = on_date
    all_payments = all(matching_date)
    all_disbursement_amounts = all_payments.collect {|payment| payment.to_money_amount(LOAN_DISBURSED)}
    all_disbursement_amounts.reduce(:+)
  end


end
