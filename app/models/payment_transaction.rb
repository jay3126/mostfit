class PaymentTransactionInfo
  attr_reader :id,
    :amount,
    :currency,
    :receipt_type,
    :payment_towards,
    :on_product_type,
    :on_product_id,
    :by_counterparty_type,
    :by_counterparty_id,
    :performed_at,
    :accounted_at,
    :performed_by,
    :recorded_by,
    :effective_on,
    :created_at

  def initialize(money_amount, receipt_type, payment_towards, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, recorded_by)
    @amount = money_amount.amount; @currency = money_amount.currency
    @receipt_type = receipt_type; @payment_towards = payment_towards
    @on_product_type = on_product_type; @on_product_id = on_product_id
    @by_counterparty_type = by_counterparty_type; @by_counterparty_id = by_counterparty_id
    @performed_at = performed_at
    @accounted_at = accounted_at
    @performed_by = performed_by
    @effective_on = effective_on
    @recorded_by = recorded_by
  end

  def payment_money_amount
    @payment_money_amount ||= Money.new(@amount, @currency)
  end

end

class PaymentTransaction
  include DataMapper::Resource
  include Constants::Properties, Constants::Money, Constants::Transaction, Constants::Accounting
  
  property :id,                   Serial
  property :amount,               *MONEY_AMOUNT_NON_ZERO
  property :currency,             *CURRENCY
  property :receipt_no,           Integer
  property :receipt_type,         Enum.send('[]', *Constants::Transaction::RECEIVED_OR_PAID), :nullable => false
  property :payment_towards,      Enum.send('[]', *Constants::Transaction::PAYMENT_TOWARDS_TYPES), :nullable => false
  property :on_product_type,      Enum.send('[]', *Constants::Transaction::TRANSACTED_PRODUCTS), :nullable => false
  property :on_product_id,        *INTEGER_NOT_NULL
  property :by_counterparty_type, Enum.send('[]', *Constants::Transaction::COUNTERPARTIES), :nullable => false
  property :by_counterparty_id,   *INTEGER_NOT_NULL
  property :performed_at,         *INTEGER_NOT_NULL
  property :accounted_at,         *INTEGER_NOT_NULL
  property :performed_by,         *INTEGER_NOT_NULL
  property :recorded_by,          *INTEGER_NOT_NULL
  property :effective_on,         *DATE_NOT_NULL
  property :accounting,           Boolean, :default => false
  property :created_at,           *CREATED_AT

  if Mfi.first.system_state != :migration
    validates_with_method :disallow_future_dated_transactions
    #validates_with_method :check_receipt_no
  end

  def disallow_future_dated_transactions
    if self.effective_on and (self.effective_on > Date.today)
      [false, "Future dated transactions are not permitted"]
    elsif(LocationHoliday.working_holiday?(self.performed_at_location, self.effective_on))
      [false, "Holiday dated transactions are not permitted"]
    else
      true
    end
  end

  def check_receipt_no
    message = ''
    if self.receipt_type == RECEIPT && self.payment_towards == PAYMENT_TOWARDS_LOAN_REPAYMENT
      if self.receipt_no.blank?
        message = [false, "Receipt Number cannot be blank"]
      elsif !PaymentTransaction.first(:receipt_no => self.receipt_no).blank?
        message =  [false, "Receipt Number is not valid"]
      end
    end
    message.blank? ? true : message
  end

  def money_amounts; [ :amount ]; end
  def payment_money_amount; to_money_amount(:amount); end

  def on_product_instance; Resolver.fetch_product_instance(self.on_product_type, self.on_product_id); end
  def by_counterparty; Resolver.fetch_counterparty(self.by_counterparty_type, self.by_counterparty_id); end
  def performed_at_location; BizLocation.get(self.performed_at); end
  def accounted_at_location; BizLocation.get(self.accounted_at); end
  def performed_by_staff; StaffMember.get(self.performed_by); end
  def recorded_by_user; User.get(self.recorded_by); end

  def product_action
    PRODUCT_ACTIONS_FOR_PAYMENT_TRANSACTIONS[self.on_product_type][self.receipt_type][self.payment_towards]
  end

  # UPDATES

  def self.record_payment(money_amount, receipt_type, payment_towards, receipt_no, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, recorded_by)
    Validators::Arguments.not_nil?(money_amount, receipt_type, payment_towards, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, recorded_by)
    # TO BE INTRODUCED
    # Validators::Arguments.is_id?(on_product_id, by_counterparty_id, performed_at, accounted_at, performed_by, recorded_by)
    payment = to_payment(money_amount, receipt_type, payment_towards, receipt_no, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, recorded_by)
    recorded_payment = create(payment)
    raise Errors::DataError, recorded_payment.errors.first.first unless recorded_payment.saved?
    recorded_payment
  end

  private

  # Constructs the hash required to create a payment
  def self.to_payment(money_amount, receipt_type, payment_towards, receipt_no, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, recorded_by)
    payment = {}
    payment[:amount] = money_amount.amount; payment[:currency] = money_amount.currency
    payment[:receipt_type] = receipt_type; payment[:payment_towards] = payment_towards
    payment[:receipt_no] = receipt_no unless receipt_no.blank?
    payment[:on_product_type] = on_product_type; payment[:on_product_id] = on_product_id
    payment[:by_counterparty_type] = by_counterparty_type; payment[:by_counterparty_id] = by_counterparty_id
    payment[:performed_at] = performed_at; payment[:accounted_at] = accounted_at
    payment[:performed_by] = performed_by
    payment[:effective_on]  = effective_on
    payment[:recorded_by] = recorded_by
    payment
  end

end
