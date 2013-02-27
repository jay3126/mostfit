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
  include LoanLifeCycle
  
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
  property :deleted_at,           ParanoidDateTime
  property :updated_at,           DateTime

  has 1, :loan_receipt
  has 1, :fee_receipt
  has 1, :loan_payment
  has 1, :voucher
  
  if Mfi.first.system_state != :migration
    validates_with_method :disallow_future_dated_transactions
    validates_with_method :is_payment_permitted?
    #validates_with_method :check_receipt_no
  end

  def disallow_future_dated_transactions
    if self.effective_on and (self.effective_on > Date.today)
      [false, "Future dated transactions are not permitted"]
      #    elsif(LocationHoliday.working_holiday?(self.performed_at_location, self.effective_on))
      #      [false, "Holiday dated transactions are not permitted"]
    else
      true
    end
  end

  def is_payment_permitted?
    if self.on_product_type == :lending
      loan = Lending.get(self.on_product_id)
      if loan.blank?
        [false, "Loan Not Exists"]
      else
        loan.is_payment_permitted?(self)
      end
    end
  end

  def check_receipt_no
    message = ''
    if self.receipt_type == RECEIPT && [PAYMENT_TOWARDS_LOAN_REPAYMENT, PAYMENT_TOWARDS_LOAN_RECOVERY, PAYMENT_TOWARDS_LOAN_PRECLOSURE].include?(self.payment_towards)
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

  def self.bulk_record_payment(obj = [])
    last_id = PaymentTransaction.last.id
    values = []
    obj.each do |payment|
      last_id += 1
      amount = payment.amount
      currency = Constants::Money::CURRENCIES.index(payment.currency).blank? ? 0 : Constants::Money::CURRENCIES.index(:INR)+1
      receipt_no = payment.receipt_no.blank? ? '' : payment.receipt_no
      receipt_type = Constants::Transaction::RECEIVED_OR_PAID.index(payment.receipt_type)+1
      payment_towards = Constants::Transaction::PAYMENT_TOWARDS_TYPES.index(payment.payment_towards)+1
      on_product_type = Constants::Transaction::TRANSACTED_PRODUCTS.index(payment.on_product_type)+1
      on_product_id = payment.on_product_id
      by_counterparty_type = Constants::Transaction::COUNTERPARTIES.index(payment.by_counterparty_type)+1
      by_counterparty_id = payment.by_counterparty_id
      performed_at = payment.performed_at
      accounted_at = payment.accounted_at
      performed_by = payment.performed_by
      recorded_by = payment.recorded_by
      effective_on = payment.effective_on.strftime("%Y-%m-%d")
      values << "(#{last_id}, #{amount},#{currency},'#{receipt_no}',#{receipt_type},#{payment_towards},#{on_product_type}, #{on_product_id}, #{by_counterparty_type},#{by_counterparty_id},#{performed_at},#{accounted_at}, #{performed_by},#{recorded_by},'#{effective_on}')"
    end
    if values.blank?
      ''
    else
      "INSERT INTO payment_transactions (id, amount, currency,receipt_no,receipt_type,payment_towards,on_product_type,on_product_id, by_counterparty_type,by_counterparty_id,performed_at,accounted_at,performed_by,recorded_by,effective_on) VALUES #{values.join(',')}"
    end
  end

  def delete_payment_transaction
    if REVERT_PAYMENT_TOWARDS.include?(self.payment_towards)
      loan_receipt = self.loan_receipt
      voucher = self.voucher
      loan = Lending.get self.on_product_id
      p_vouchers = []
      postings = voucher.blank? ? [] : voucher.ledger_postings
      fee_receipt = self.fee_receipt
      ledger = ''
      if voucher.blank?
        product_action = self.product_action
        product_accounting_rule = ProductAccountingRule.resolve_rule_for_product_action(product_action)
        posting_rules = product_accounting_rule.product_posting_rules
        posting_rules.each do |pr|
          ledger = LedgerAssignment.locate_ledger(self.by_counterparty_type, self.by_counterparty_id, pr.ledger_classification, self.on_product_type, self.on_product_id)
          p_vouchers = ledger.blank? ? [] : ledger.vouchers(:effective_on => self.effective_on, :total_amount => self.amount)
          break unless p_vouchers.blank?
        end
        unless p_vouchers.blank?
          voucher = p_vouchers.first
          postings = voucher.blank? ? [] : voucher.ledger_postings
        end
      end
      if loan.is_repaid?
        last_status = loan.loan_status_changes.first(:from_status => DISBURSED_LOAN_STATUS, :to_status => REPAID_LOAN_STATUS)
        repaid_status = loan.loan_repaid_status
        repaid_status.destroy! unless repaid_status.blank?
        last_status.destroy! unless last_status.blank?
        loan.repaid_on_date = nil
        loan.repaid_by_staff = nil
        loan.status = DISBURSED_LOAN_STATUS
        loan.save!
      elsif loan.is_preclosed?
        last_status = loan.loan_status_changes.first(:from_status => DISBURSED_LOAN_STATUS, :to_status => PRECLOSED_LOAN_STATUS)
        repaid_status = loan.loan_repaid_status
        repaid_status.destroy! unless repaid_status.blank?
        last_status.destroy! unless last_status.blank?
        loan.preclosed_on_date = nil
        loan.preclosed_by_staff = nil
        loan.status = DISBURSED_LOAN_STATUS
        loan.save!
      end
      loan_receipt.update!(:deleted_at => DateTime.now) unless loan_receipt.blank?
      fee_receipt.update!(:deleted_at => DateTime.now) unless fee_receipt.blank?
      voucher.update!(:deleted_at => DateTime.now) unless voucher.blank?
      postings.each{|p| p.update!(:deleted_at => DateTime.now)} unless postings.blank?
      self.deleted_at = DateTime.now
      self.save!
    end

  end

  def self.delete_payment_transaction(p_id)
    payment = get(p_id)
    payment.delete_payment_transaction
  end

  def self.fee_payment_transaction_for_jan
    fee_payments = all(:payment_towards => PAYMENT_TOWARDS_FEE_RECEIPT, :effective_on.lte => Date.new(2013,1,31), :effective_on.gte => Date.new(2013,1,1))
    bk = MyBookKeeper.new
    fee_payments.each do |payment|
      bk.account_for_payment_transaction(payment, {:total_received => payment.to_money[:amount]})
    end
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
