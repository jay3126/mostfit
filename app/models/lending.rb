class Lending
  include DataMapper::Resource
  include LoanLifeCycle
  include Constants::Money, Constants::Loan, Constants::LoanAmounts, Constants::Properties, Constants::Transaction
  include Validators::Arguments
  include MarkerInterfaces::Recurrence
  include LoanUtility

  property :id,                             Serial
  property :lan,                            *UNIQUE_ID
  property :applied_amount,                 *MONEY_AMOUNT
  property :currency,                       *CURRENCY
  property :applied_on_date,                *DATE_NOT_NULL
  property :approved_amount,                *MONEY_AMOUNT_NULL
  property :disbursed_amount,               *MONEY_AMOUNT_NULL
  property :scheduled_disbursal_date,       *DATE_NOT_NULL
  property :scheduled_first_repayment_date, *DATE_NOT_NULL
  property :approved_on_date,               *DATE
  property :disbursal_date,                 *DATE
  property :repaid_on_date,                 *DATE
  property :repayment_frequency,            *FREQUENCY
  property :tenure,                         *TENURE
  property :administered_at_origin,         *INTEGER_NOT_NULL
  property :accounted_at_origin,            *INTEGER_NOT_NULL
  property :applied_by_staff,               *INTEGER_NOT_NULL
  property :approved_by_staff,              Integer
  property :disbursed_by_staff,             Integer
  property :recorded_by_user,               *INTEGER_NOT_NULL
  property :repayment_allocation_strategy,  Enum.send('[]', *LOAN_REPAYMENT_ALLOCATION_STRATEGIES), :nullable => false
  property :status,                         Enum.send('[]', *LOAN_STATUSES), :nullable => false, :default => STATUS_NOT_SPECIFIED
  property :loan_purpose,                   String
  property :created_at,                     *CREATED_AT
  property :updated_at,                     *UPDATED_AT
  property :deleted_at,                     *DELETED_AT

  def administered_at_origin_location; BizLocation.get(self.administered_at_origin); end
  def accounted_at_origin_location; BizLocation.get(self.accounted_at_origin); end

  # Lists the properties that are money amounts
  def money_amounts
    [:applied_amount, :approved_amount, :disbursed_amount]
  end

  # TODO to be deprecated
  def disbursal_date_value
    self.disbursal_date ? self.disbursal_date : self.scheduled_disbursal_date
  end

  # lending descriptions in one line
  def to_s
    "Loan for applied amount: #{to_money_amount(:applied_amount).to_s} applied on #{applied_on_date}"
  end

  belongs_to :lending_product
  belongs_to :loan_borrower
  has 1, :loan_base_schedule
  has n, :loan_payments
  has n, :loan_receipts
  has n, :loan_status_changes
  has n, :loan_due_statuses
  has 1, :loan_repaid_status
  has n, :simple_insurance_policies

  # Creates a new loan
  def self.create_new_loan(
      applied_amount,
      repayment_frequency,
      tenure,
      from_lending_product,
      for_borrower,
      administered_at_origin,
      accounted_at_origin,
      applied_on_date,
      scheduled_disbursal_date,
      scheduled_first_repayment_date,
      applied_by_staff,
      recorded_by_user,
      lan = nil,
      loan_purpose = nil
    )
    new_loan_borrower = LoanBorrower.assign_loan_borrower(for_borrower, applied_on_date, administered_at_origin, accounted_at_origin, applied_by_staff, recorded_by_user)

    new_loan  = to_loan(
      applied_amount,
      repayment_frequency,
      tenure,
      from_lending_product,
      new_loan_borrower,
      administered_at_origin,
      accounted_at_origin,
      applied_on_date,
      scheduled_disbursal_date,
      scheduled_first_repayment_date,
      applied_by_staff,
      recorded_by_user,
      lan,
      loan_purpose
    )

    total_interest_applicable = from_lending_product.total_interest_money_amount
    num_of_installments = tenure
    principal_and_interest_amounts = from_lending_product.amortization
    # TODO create a LoanAdministration instance for the loan administered_at_origin and accounted_at_origin
    new_loan.set_status(NEW_LOAN_STATUS, applied_on_date)
    LoanBaseSchedule.create_base_schedule(
      applied_amount,
      total_interest_applicable,
      scheduled_disbursal_date,
      scheduled_first_repayment_date,
      repayment_frequency,
      num_of_installments,
      new_loan,
      principal_and_interest_amounts)
    LoanAdministration.assign(new_loan.administered_at_origin_location, new_loan.accounted_at_origin_location, new_loan, applied_by_staff, recorded_by_user, applied_on_date)
    new_loan
  end

  #############
  # Validations # begins
  #############

  def is_payment_permitted?(payment_transaction)
    transaction_receipt_type = payment_transaction.receipt_type
    transaction_effective_on = payment_transaction.effective_on
    transaction_money_amount = payment_transaction.payment_money_amount
    
    Validators::Arguments.not_nil?(transaction_receipt_type, transaction_effective_on, transaction_money_amount)

    #payments
    if transaction_receipt_type == PAYMENT
      return [false, "Loan cannot be disbursed unless approved"] unless self.is_approved?
    end

    #receipts
    if transaction_receipt_type == RECEIPT
      return [false, "Repayments cannot be accepted on loans that are not outstanding"] unless is_outstanding_on_date?(transaction_effective_on)
      
      maximum_receipt_to_accept = actual_total_outstanding_net_advance_balance
      if (maximum_receipt_to_accept < transaction_money_amount)
        return [false, "Repayment cannot be accepted on the loan at the moment exceeding #{maximum_receipt_to_accept.to_s}"]
      end
    end

    true
  end

  #############
  # Validations # ends
  #############

  ########################
  # LOAN SCHEDULE DATES # begins
  ########################

  # Gets the list of schedule dates
  def schedule_dates
    raise Errors::InitialisationNotCompleteError, "A loan base schedule is not currently available for the loan to provide schedule dates" unless self.loan_base_schedule
    self.loan_base_schedule.get_schedule_dates
  end

  def last_scheduled_date
    schedule_dates.sort.last
  end

  # Gets a Range that begins with the first schedule date (disbursement) and ends with the last schedule date
  def schedule_date_range
    raise Errors::InitialisationNotCompleteError, "A loan base schedule is not currently available for the loan to provide schedule dates" unless self.loan_base_schedule
    self.loan_base_schedule.get_schedule_date_range
  end

  # Tests the specified date for whether it is a schedule date
  def schedule_date?(on_date)
    raise Errors::InitialisationNotCompleteError, "A loan base schedule is not currently available for the loan to provide schedule dates" unless self.loan_base_schedule
    self.loan_base_schedule.is_schedule_date?(on_date)
  end

  # Gets the immediately previous and current (or next) schedule dates
  def previous_and_current_schedule_dates(for_date)
    raise Errors::InitialisationNotCompleteError, "A loan base schedule is not currently available for the loan to provide schedule dates" unless self.loan_base_schedule
    self.loan_base_schedule.get_previous_and_current_schedule_dates(for_date)
  end

  def previous_and_current_amortization_items(for_date)
    raise Errors::InitialisationNotCompleteError, "A loan base schedule is not currently available for the loan to provide schedule dates" unless self.loan_base_schedule
    self.loan_base_schedule.get_previous_and_current_amortization_items(for_date)
  end

  #######################
  # LOAN SCHEDULE DATES # ends
  #######################

  ############
  # Borrower # begins
  ############

  # Gets the instance of borrower
  def borrower; self.loan_borrower ? self.loan_borrower.counterparty : nil; end

  ############
  # Borrower # ends
  ############

  ################
  # LOAN AMOUNTS # begins
  ################

  # TODO on loan amounts
  # TOTAL_LOAN_DISBURSED amount to be calculated on the basis of disbursements from payments
  # TOTAL_INTEREST_APPLICABLE amount to be (re)calculated whenever there is a disbursement

  # The total loan amount disbursed
  def total_loan_disbursed
    self.loan_payments.sum_till_date || zero_money_amount
  end

  # The total interest applicable as computed at the time that the loan was disbursed
  def total_interest_applicable
    raise Errors::InitialisationNotCompleteError, "A loan base schedule is not currently available for the loan" unless self.loan_base_schedule
    self.loan_base_schedule.total_interest_applicable_money_amount
  end

  ################
  # LOAN AMOUNTS # ends
  ################

  #########################
  # LOAN BALANCES QUERIES # begins
  #########################

  def scheduled_principal_due(on_date)
    return zero_money_amount if (on_date < scheduled_first_repayment_date)

    amortization = get_scheduled_amortization(on_date)
    amortization.values.first[SCHEDULED_PRINCIPAL_DUE] if amortization
  end

  def scheduled_principal_outstanding(on_date)
    return zero_money_amount if on_date < scheduled_first_repayment_date

    amortization = get_scheduled_amortization(on_date)
    amortization.values.first[SCHEDULED_PRINCIPAL_OUTSTANDING] if amortization
  end

  def scheduled_interest_due(on_date)
    return zero_money_amount if on_date < scheduled_first_repayment_date

    amortization = get_scheduled_amortization(on_date)
    amortization.values.first[SCHEDULED_INTEREST_DUE] if amortization
  end

  def scheduled_interest_outstanding(on_date)
    return zero_money_amount if on_date < scheduled_first_repayment_date

    amortization = get_scheduled_amortization(on_date)
    amortization.values.first[SCHEDULED_INTEREST_OUTSTANDING] if amortization
  end

  def scheduled_total_outstanding(on_date)
    scheduled_principal_outstanding(on_date) + scheduled_interest_outstanding(on_date)
  end

  def scheduled_principal_and_interest_due(on_date)
    {SCHEDULED_PRINCIPAL_DUE => scheduled_principal_due(on_date), SCHEDULED_INTEREST_DUE => scheduled_interest_due(on_date)}
  end

  def scheduled_total_due(on_date)
    scheduled_principal_due(on_date) + scheduled_interest_due(on_date)
  end

  def actual_principal_outstanding
    return zero_money_amount unless is_outstanding?

    if (total_loan_disbursed > principal_received_till_date)
      return (total_loan_disbursed - principal_received_till_date)
    end
    zero_money_amount
  end

  def actual_interest_outstanding
    return zero_money_amount unless is_outstanding?

    if (total_interest_applicable > interest_received_till_date)
      return (total_interest_applicable - interest_received_till_date)
    end
    zero_money_amount
  end

  def sum_of_oustanding_and_due_principal(on_date)
    scheduled_principal_outstanding(on_date) + scheduled_principal_due(on_date)
  end

  def sum_of_oustanding_and_due_interest(on_date)
    scheduled_interest_outstanding(on_date) + scheduled_interest_due(on_date)
  end

  def sum_of_outstanding_and_due_total(on_date)
    sum_of_oustanding_and_due_principal(on_date) + sum_of_oustanding_and_due_interest(on_date)
  end

  def actual_total_due(on_date)    
    net_outstanding = actual_total_outstanding_net_advance_balance
    scheduled_outstanding = scheduled_total_outstanding(on_date)

    (net_outstanding > scheduled_outstanding) ? (net_outstanding - scheduled_outstanding) :
      zero_money_amount
  end

  def actual_total_outstanding_net_advance_balance
    if (actual_total_outstanding > current_advance_available)
      return (actual_total_outstanding - current_advance_available)
    end
    zero_money_amount
  end

  def actual_total_outstanding
    actual_principal_outstanding + actual_interest_outstanding
  end

  def broken_period_interest_due(on_date)
    return zero_money_amount unless (self.disbursal_date and on_date > self.disbursal_date)
    return zero_money_amount if schedule_date?(on_date)
    return zero_money_amount if on_date >= last_scheduled_date

    previous_schedule_date = Constants::Time.get_immediately_earlier_date(on_date, *schedule_dates)
    next_schedule_date = Constants::Time.get_immediately_next_date(on_date, *schedule_dates)

    ios_earlier = scheduled_interest_outstanding(previous_schedule_date)
    ios_later = scheduled_interest_outstanding(next_schedule_date)

    Allocation::Common.calculate_broken_period_interest(ios_earlier, ios_later, previous_schedule_date, next_schedule_date, on_date)
  end
  
  def get_scheduled_amortization(on_date)
    #TODO determine what is to be done before the scheduled first repayment date for amortization
    return nil if on_date < scheduled_first_repayment_date

    raise Errors::InitialisationNotCompleteError, "A loan base schedule is not currently available for the loan" unless self.loan_base_schedule
    previous_and_current_amortization_items_val = self.loan_base_schedule.get_previous_and_current_amortization_items(on_date)
    earlier_amortization_item = previous_and_current_amortization_items_val.is_a?(Array) ? previous_and_current_amortization_items_val.first :
      previous_and_current_amortization_items_val

    earlier_amortization_item
  end

  #########################
  # LOAN BALANCES QUERIES # ends
  #########################

  ########
  # Fees # begins
  ########

  def all_applicable_loan_fees
    FeeInstance.get_all_fees_for_instance(self)
  end
  
  def unpaid_loan_fees
    FeeInstance.get_unpaid_fees_for_instance(self)
  end

  def get_preclosure_penalty_product
    SimpleFeeProduct.get_applicable_preclosure_penalty(self.lending_product_id)
  end

  ########
  # Fees # ends
  ########

  ########################################################
  # LOAN PAYMENTS, RECEIPTS, ADVANCES, ALLOCATION  QUERIES # begins
  ########################################################

  def current_advance_available
    historical_advance_available(Date.today)
  end

  def historical_advance_available(on_date)
    # TODO implement using accounting facade
    advance_received_till_date(on_date)
  end

  def amounts_received_on_date(on_date = Date.today)
    self.loan_receipts.sum_on_date(on_date)
  end

  def principal_received_on_date(on_date = Date.today); amounts_received_on_date(on_date)[PRINCIPAL_RECEIVED]; end
  def interest_received_on_date(on_date = Date.today); amounts_received_on_date(on_date)[INTEREST_RECEIVED]; end
  def advance_received_on_date(on_date = Date.today); amounts_received_on_date(on_date)[ADVANCE_RECEIVED]; end

  def total_received_on_date(on_date = Date.today)
    principal_received_on_date(on_date) + interest_received_on_date(on_date) + advance_received_on_date(on_date)
  end

  def amounts_received_till_date(on_date = Date.today)
    historical_amounts_received_till_date(on_date)
  end

  def historical_amounts_received_till_date(on_or_before_date)
    self.loan_receipts.sum_till_date(on_or_before_date)
  end

  def principal_received_till_date(on_date = Date.today); amounts_received_till_date(on_date)[PRINCIPAL_RECEIVED]; end
  def interest_received_till_date(on_date = Date.today); amounts_received_till_date(on_date)[INTEREST_RECEIVED]; end
  def advance_received_till_date(on_date = Date.today); amounts_received_till_date(on_date)[ADVANCE_RECEIVED]; end

  def total_received_till_date
    principal_received_till_date + interest_received_till_date + advance_received_till_date
  end

  def advance_adjusted_till_date(on_date = Date.today); zero_money_amount; end
  def advance_adjusted_on_date(on_date = Date.today); zero_money_amount; end
  def advance_balance(on_date = Date.today); zero_money_amount; end

  ########################################################
  # LOAN PAYMENTS, RECEIPTS, ADVANCES, ALLOCATION  QUERIES # ends
  ########################################################

  #######################
  # LOAN STATUS QUERIES # begins
  #######################

  # Obtain the loan status as on a particular date
  def historical_loan_status_on_date(on_date)
    status_in_force_on_date = self.loan_status_changes.status_in_force(on_date)
    status_in_force_on_date.to_status
  end

  def is_outstanding_now?
    is_outstanding_on_date?(Date.today)
  end

  def is_outstanding_on_date?(on_date)
    loan_status_on_date = historical_loan_status_on_date(on_date)
    LoanLifeCycle.is_outstanding_status?(loan_status_on_date)
  end

  #######################
  # LOAN STATUS QUERIES # ends
  #######################

  #########################
  # LOAN DUE STATUS QUERIES # begins
  #########################

  def current_due_status
    return NOT_APPLICABLE unless is_outstanding_now?
    due_status_from_outstanding(Date.today)
  end
  
  def due_status_from_outstanding(on_date)
    return NOT_APPLICABLE unless is_outstanding_on_date?(on_date)
    return NOT_DUE if (on_date < self.scheduled_first_repayment_date)
    (actual_total_outstanding_net_advance_balance > scheduled_total_outstanding(on_date)) ? OVERDUE : DUE
  end

  def get_loan_due_status_record(on_date)
    LoanDueStatus.most_recent_status_record_on_date(self.id, on_date)
  end

  def generate_loan_due_status_record(on_date)
    LoanDueStatus.generate_loan_due_status(self.id, on_date)
  end

  def days_past_due
    days_past_due_on_date(Date.today)
  end

  def days_past_due_on_date(on_date)
    return 0 unless is_outstanding_on_date?(on_date)
    LoanDueStatus.unbroken_days_past_due(self.id, on_date)
  end

  ###########################
  # LOAN LIFE-CYCLE ACTIONS # begins
  ###########################

  def allocate_payment(payment_transaction, loan_action, make_specific_allocation = false, specific_principal_amount = nil, specific_interest_amount = nil)
    is_transaction_permitted_val = is_payment_permitted?(payment_transaction)

    if (make_specific_allocation)
      raise ArgumentError, "A principal and interest amount to allocate must be specified" unless (specific_principal_amount and specific_interest_amount)
      
      total_principal_and_interest = specific_principal_amount + specific_interest_amount
      if (total_principal_and_interest > actual_total_outstanding_net_advance_balance)
        raise Errors::BusinessValidationError, "Total principal and interest amount to allocate cannot exceed loan amount outstanding"
      end
    end

    is_transaction_permitted, error_message = is_transaction_permitted_val.is_a?(Array) ? [is_transaction_permitted_val.first, is_transaction_permitted_val.last] :
      [true, nil]
    raise Errors::BusinessValidationError, error_message unless is_transaction_permitted

    allocation = nil
    case loan_action
      when LOAN_DISBURSEMENT then allocation = disburse(payment_transaction)
      when LOAN_REPAYMENT then allocation = repay(payment_transaction)
      when LOAN_PRECLOSURE then allocation = preclose(payment_transaction, specific_principal_amount, specific_interest_amount)
      else
        raise Errors::OperationNotSupportedError, "Operation #{loan_action} is currently not supported"
    end
    process_allocation(payment_transaction, loan_action, allocation)
  end

  def process_allocation(payment_transaction, loan_action, allocation)
    generate_loan_due_status_record(payment_transaction.effective_on)
    process_status_change(payment_transaction, loan_action, allocation)
    allocation
  end

  def process_status_change(payment_transaction, loan_action, allocation)
    if payment_transaction.receipt_type == RECEIPT
      if loan_action == LOAN_REPAYMENT
        if (actual_total_outstanding == zero_money_amount)
          repaid_nature = LoanLifeCycle::REPAYMENT_ACTIONS_AND_REPAID_NATURES[loan_action]
          raise Errors::BusinessValidationError, "Repaid nature not configured for loan action: #{loan_action}" unless repaid_nature
          mark_loan_repaid(repaid_nature, payment_transaction.effective_on, actual_principal_outstanding, actual_interest_outstanding)
        end
      elsif loan_action == LOAN_PRECLOSURE
        repaid_nature = LoanLifeCycle::REPAYMENT_ACTIONS_AND_REPAID_NATURES[loan_action]
        raise Errors::BusinessValidationError, "Repaid nature not configured for loan action: #{loan_action}" unless repaid_nature
        mark_loan_repaid(repaid_nature, payment_transaction.effective_on, actual_principal_outstanding, actual_interest_outstanding)
      end
    end
  end

  def mark_loan_repaid(repaid_nature, repaid_on_date, closing_principal_outstanding, closing_interest_outstanding)
    self.loan_repaid_status = LoanRepaidStatus.to_loan_repaid_status(self, repaid_nature, repaid_on_date, closing_principal_outstanding, closing_interest_outstanding)
    set_status(REPAID_LOAN_STATUS, repaid_on_date)
  end

  def approve(approved_amount, approved_on_date, approved_by)
    Validators::Arguments.not_nil?(approved_amount, approved_on_date, approved_by)
    raise Errors::BusinessValidationError, "approved amount #{approved_amount.to_s} cannot exceed applied amount #{to_money_amount(self.applied_amount)}" if approved_amount.amount > self.applied_amount
    raise Errors::BusinessValidationError, "approved on date: #{approved_on_date} cannot precede the applied on date #{applied_on_date}" if approved_on_date < applied_on_date
    raise Errors::InvalidStateChangeError, "Only a new loan can be approved" unless current_loan_status == NEW_LOAN_STATUS

    self.approved_amount   = approved_amount.amount
    self.approved_on_date  = approved_on_date
    self.approved_by_staff = approved_by
    set_status(APPROVED_LOAN_STATUS, approved_on_date)
    setup_fee_instances
    setup_insurance_policies
  end

  def setup_fee_instances
    loan_fee_product_map = get_loan_fee_product
    if loan_fee_product_map
      loan_fee_product_map.values.each {|loan_fee_product_instance|
        FeeInstance.register_fee_instance(loan_fee_product_instance, self, self.administered_at_origin, self.accounted_at_origin, self.scheduled_disbursal_date)
      }
    end
  end

  def setup_insurance_policies
    insurance_products = get_insurance_products_and_premia.keys
    insurance_products.each { |product|
      SimpleInsurancePolicy.setup_proposed_insurance(self.scheduled_disbursal_date, product, self.borrower, self)
    }
  end

  def disburse(by_disbursement_transaction)
    Validators::Arguments.not_nil?(by_disbursement_transaction)

    raise Errors::InvalidStateChangeError, "Only a loan that is approved can be disbursed" unless current_loan_status == APPROVED_LOAN_STATUS

    on_disbursal_date = by_disbursement_transaction.effective_on
    raise Errors::BusinessValidationError, "disbursal date: #{on_disbursal_date} cannot precede approval date: #{approved_on_date}" if on_disbursal_date < self.approved_on_date

    #TODO validate and respond to any changes in the scheduled_first_repayment_date
    self.disbursed_amount   = by_disbursement_transaction.amount
    self.disbursal_date     = on_disbursal_date
    self.disbursed_by_staff = by_disbursement_transaction.performed_by
    set_status(DISBURSED_LOAN_STATUS, on_disbursal_date)
    disbursement_money_amount = by_disbursement_transaction.payment_money_amount
    LoanPayment.record_loan_payment(disbursement_money_amount, self, on_disbursal_date)
    disbursement_allocation = {LOAN_DISBURSED => by_disbursement_transaction.payment_money_amount}
    disbursement_allocation = Money.add_total_to_map(disbursement_allocation, TOTAL_PAID)
    disbursement_allocation
  end

  def repay(by_receipt)
    update_for_payment(by_receipt)
  end

  def preclose(by_receipt, principal_money_amount, interest_money_amount)
    make_specific_allocation = true
    update_for_payment(by_receipt, make_specific_allocation, principal_money_amount, interest_money_amount)
  end

  ###########################
  # LOAN LIFE-CYCLE ACTIONS # ends
  ###########################

  ###########
  # UPDATES # begins
  ###########

  # Set the loan status
  def set_status(new_loan_status, effective_on)
    current_status = self.status
    raise Errors::InvalidStateChangeError, "Loan status is already #{new_loan_status}" if current_status == new_loan_status
    self.status = new_loan_status
    raise Errors::DataError, errors.first.first unless save
    LoanStatusChange.record_status_change(self, current_status, new_loan_status, effective_on)
  end

  private

  def get_loan_fee_product
    SimpleFeeProduct.get_applicable_fee_products_on_loan_product(self.lending_product.id)
  end

  def get_insurance_products_and_premia
    insurance_products_and_premia = {}
    insurance_products_on_loan = self.lending_product.simple_insurance_products
    insurance_products_on_loan.each { |insurance_product|
      premium_map = SimpleFeeProduct.get_applicable_premium_on_insurance_product(insurance_product.id)
      premium_fee_product = premium_map[Constants::Transaction::PREMIUM_COLLECTED_ON_INSURANCE]
      raise Errors::InvalidConfigurationError, "An insurance premium has not been configured for the insurance product: #{insurance_product.to_s}" unless premium_fee_product
      insurance_products_and_premia[insurance_product] = premium_fee_product
    }
    insurance_products_and_premia
  end

  def self.to_loan(for_amount, repayment_frequency, tenure, from_lending_product, new_loan_borrower,
      administered_at_origin, accounted_at_origin, applied_on_date, scheduled_disbursal_date, scheduled_first_repayment_date,
      applied_by_staff, recorded_by_user, lan = nil, loan_purpose = nil)
    Validators::Arguments.not_nil?(for_amount, repayment_frequency, tenure, from_lending_product, new_loan_borrower,
      administered_at_origin, accounted_at_origin, applied_on_date, scheduled_disbursal_date,
      scheduled_first_repayment_date, applied_by_staff, recorded_by_user)
    loan_hash                                  = { }
    loan_hash[:applied_amount]                 = for_amount.amount
    loan_hash[:currency]                       = for_amount.currency
    loan_hash[:loan_borrower]                  = new_loan_borrower
    loan_hash[:repayment_frequency]            = repayment_frequency
    loan_hash[:tenure]                         = tenure
    loan_hash[:lending_product]                = from_lending_product
    loan_hash[:applied_on_date]                = applied_on_date
    loan_hash[:applied_by_staff]               = applied_by_staff
    loan_hash[:administered_at_origin]         = administered_at_origin
    loan_hash[:accounted_at_origin]            = accounted_at_origin
    loan_hash[:scheduled_disbursal_date]       = scheduled_disbursal_date
    loan_hash[:scheduled_first_repayment_date] = scheduled_first_repayment_date
    loan_hash[:recorded_by_user]               = recorded_by_user
    loan_hash[:repayment_allocation_strategy]  = from_lending_product.repayment_allocation_strategy
    loan_hash[:status]                         = STATUS_NOT_SPECIFIED
    loan_hash[:lan]                            = lan if lan
    loan_hash[:loan_purpose]                   = loan_purpose if loan_purpose
    Lending.new(loan_hash)
  end

  # All actions required to update the loan for the payment
  def update_for_payment(payment_transaction, make_specific_allocation = false, specific_principal_money_amount = nil, specific_interest_money_amount = nil)
    payment_amount = payment_transaction.payment_money_amount
    effective_on = payment_transaction.effective_on
    performed_at = payment_transaction.performed_at
    accounted_at = payment_transaction.accounted_at
    payment_allocation = make_allocation(payment_amount, effective_on, make_specific_allocation, specific_principal_money_amount, specific_interest_money_amount)
    loan_receipt = LoanReceipt.record_allocation_as_loan_receipt(payment_allocation, performed_at, accounted_at, self, effective_on)
    payment_allocation
  end

  # Record an allocation on the loan for the given total amount
  def make_allocation(total_amount, on_date, make_specific_allocation = false, specific_principal_money_amount = nil, specific_interest_money_amount = nil)
    payment_currency = total_amount.currency
    resulting_allocation = Hash.new(zero_money_amount)

    if (make_specific_allocation)
      raise ArgumentError, "Specific principal amount was not available" unless (specific_principal_money_amount and (specific_principal_money_amount.is_a?(Money)))
      raise ArgumentError, "Specific interest amount was not available" unless (specific_interest_money_amount and (specific_interest_money_amount.is_a?(Money)))

      resulting_allocation[PRINCIPAL_RECEIVED] = specific_principal_money_amount
      resulting_allocation[INTEREST_RECEIVED]  = specific_interest_money_amount
      resulting_allocation[ADVANCE_RECEIVED]   = zero_money_amount
      resulting_allocation = Money.add_total_to_map(resulting_allocation, TOTAL_RECEIVED)
      return resulting_allocation
    end

    #allocate when not due
    if current_due_status == NOT_DUE
      resulting_allocation[ADVANCE_RECEIVED] = total_amount
      resulting_allocation = Money.add_total_to_map(resulting_allocation, TOTAL_RECEIVED)
      return resulting_allocation
    end

    #TODO handle scenario where repayment is received between schedule dates

    only_principal_and_interest = [self.actual_total_due(on_date), total_amount].min
    advance_to_allocate = (total_amount > only_principal_and_interest) ?
      (total_amount - only_principal_and_interest) : zero_money_amount

    fresh_allocation = allocate_principal_and_interest(only_principal_and_interest, on_date)

    resulting_allocation[PRINCIPAL_RECEIVED] = fresh_allocation[:principal]
    resulting_allocation[INTEREST_RECEIVED] = fresh_allocation[:interest]
    advance_to_allocate += fresh_allocation[:amount_not_allocated]
    resulting_allocation[ADVANCE_RECEIVED] = advance_to_allocate
    resulting_allocation = Money.add_total_to_map(resulting_allocation, TOTAL_RECEIVED)
    resulting_allocation
  end

  def allocate_principal_and_interest(total_money_amount, on_date)
    earlier_allocation = {}
    earlier_allocation[:principal] = principal_received_till_date(on_date)
    earlier_allocation[:interest]  = interest_received_till_date(on_date)

    # Netoff the amount received earlier against earlier amortization items
    all_previous_amortization_items = get_all_amortization_items_till_date(on_date)
    unallocated_amortization_items = allocator.netoff_allocation(earlier_allocation, all_previous_amortization_items)

    # Allocation to be done on the amount that is not advance
    allocation = allocator.allocate(total_money_amount, unallocated_amortization_items)
    allocation
  end

  ###########
  # UPDATES # ends
  ###########

  def get_all_amortization_items_till_date(on_date)
    raise Errors::InitialisationNotCompleteError, "A loan base schedule is not currently available for the loan to provide amortization" unless self.loan_base_schedule
    self.loan_base_schedule.get_all_amortization_items_till_date(on_date)
  end

  def allocator
    @allocator ||= Constants::LoanAmounts.get_allocator(self.repayment_allocation_strategy, self.currency)
  end

  ##########
  # Search # begins
  ##########

  def self.search(q, per_page)
    if /^\d+$/.match(q)
      Lending.all(:conditions => {:id => q}, :limit => per_page)
    end
  end

  ##########
  # Search # ends
  ##########

end
