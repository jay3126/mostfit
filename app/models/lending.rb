class Lending
  include DataMapper::Resource
  include Constants::Money, Constants::Loan, Constants::LoanAmounts, Constants::Properties, Constants::Transaction
  include Validators::Arguments
  include MarkerInterfaces::Recurrence, MarkerInterfaces::LoanAmountsImpl

  property :id,                             Serial
  property :lan,                            *UNIQUE_ID
  property :applied_amount,                 *MONEY_AMOUNT
  property :currency,                       *CURRENCY
  property :for_borrower_id,                *INTEGER_NOT_NULL
  property :applied_on_date,                *DATE_NOT_NULL
  property :approved_amount,                *MONEY_AMOUNT_NULL
  property :disbursed_amount,               *MONEY_AMOUNT_NULL
  property :scheduled_disbursal_date,       *DATE_NOT_NULL
  property :scheduled_first_repayment_date, *DATE_NOT_NULL
  property :disbursal_date,                 *DATE
  property :repayment_frequency,            *FREQUENCY
  property :tenure,                         *TENURE
  property :administered_at_origin,         *INTEGER_NOT_NULL
  property :accounted_at_origin,            *INTEGER_NOT_NULL
  property :applied_by_staff,               *INTEGER_NOT_NULL
  property :recorded_by_user,               *INTEGER_NOT_NULL
  property :repayment_allocation_strategy,  Enum.send('[]', *LOAN_REPAYMENT_ALLOCATION_STRATEGIES), :nullable => false
  property :status,                         Enum.send('[]', *LOAN_STATUSES), :nullable => false, :default => NEW
  property :created_at,                     *CREATED_AT
  property :updated_at,                     *UPDATED_AT
  property :deleted_at,                     *DELETED_AT

  def money_amounts;
    [:applied_amount, :approved_amount, :disbursed_amount]
  end

  def counterparty; Client.get(self.for_borrower_id); end

  belongs_to :lending_product
  has 1, :loan_base_schedule
  has n, :loan_receipts
  has n, :loan_due_statuses

  def self.create_new_loan(for_amount, repayment_frequency, tenure, from_lending_product, for_borrower_id,
      administered_at_origin, accounted_at_origin, applied_on_date, scheduled_disbursal_date, scheduled_first_repayment_date,
      applied_by_staff, recorded_by_user, lan = nil)
    new_loan  = to_loan(for_amount, repayment_frequency, tenure, from_lending_product, for_borrower_id,
                        administered_at_origin, accounted_at_origin, applied_on_date, scheduled_disbursal_date, scheduled_first_repayment_date,
                        applied_by_staff, recorded_by_user, lan)
    total_interest_money_amount = from_lending_product.total_interest_money_amount
    num_of_installments = tenure
    principal_and_interest_amounts = from_lending_product.amortization
    self.loan_base_schedule = LoanBaseSchedule.create_base_schedule(for_amount, total_interest_money_amount, scheduled_disbursal_date, scheduled_first_repayment_date, repayment_frequency, num_of_installments, new_loan, principal_and_interest_amounts)
    was_saved = new_loan.save
    raise Errors::DataError, new_loan.errors.first.first unless was_saved
    new_loan
  end

  def self.create_approved_loan(for_amount, repayment_frequency, tenure, from_lending_product, for_client,
      administered_at_origin, accounted_at_origin, applied_on_date, scheduled_disbursal_date, scheduled_first_repayment_date,
      applied_by_staff, approved_amount, approved_on_date, approved_by_staff, recorded_by_user, lan = nil)
    #TODO
  end

  ########################
  # LOAN SCHEDULE DATES # begins
  ########################

  # Gets the list of schedule dates
  def schedule_dates
    self.loan_base_schedule.get_schedule_dates
  end

  # Gets a Range that begins with the first schedule date (disbursement) and ends with the last schedule date
  def schedule_date_range
    self.loan_base_schedule.get_schedule_date_range
  end

  # Tests the specified date for whether it is a schedule date
  def schedule_date?(on_date)
    self.loan_base_schedule.is_schedule_date?(on_date)
  end

  # Gets the immediately previous and current (or next) schedule dates
  def previous_and_current_schedule_dates(for_date)
    self.loan_base_schedule.get_previous_and_current_schedule_dates(for_date)
  end

  #######################
  # LOAN SCHEDULE DATES # ends
  #######################

  #########################
  # LOAN BALANCES QUERIES # begins
  #########################

  def scheduled_principal_and_interest_due(on_date)
    self.loan_base_schedule.get_previous_and_current_amortization_items(on_date)
  end

  #########################
  # LOAN BALANCES QUERIES # ends
  #########################

  ################################################
  # LOAN PAYMENTS, RECEIPTS, ALLOCATION  QUERIES # begins
  ################################################

  def total_advance_adjusted
    #TODO
  end

  def amounts_received_on_date(on_date = Date.today)
    self.loan_receipts.sum_on_date(on_date)
  end

  def amounts_received_till_date(on_or_before_date = Date.today)
    self.loan_receipts.sum_till_date(on_or_before_date)
  end

  def total_received_on_date(on_date = Date.today)
    principal_received_on_date(on_date) + interest_received_on_date(on_date) + advance_received_on_date(on_date)
  end

  def principal_received_on_date(on_date = Date.today); amounts_received_on_date(on_date)[PRINCIPAL_RECEIVED]; end
  def interest_received_on_date(on_date = Date.today); amounts_received_on_date(on_date)[INTEREST_RECEIVED]; end
  def advance_received_on_date(on_date = Date.today); amounts_received_on_date(on_date)[ADVANCE_RECEIVED]; end

  def total_received_till_date(on_or_before_date = Date.today)
    principal_received_till_date(on_or_before_date) + interest_received_till_date(on_or_before_date) + advance_received_till_date(on_or_before_date)
  end

  def principal_received_till_date(on_or_before_date = Date.today); amounts_received_till_date(on_or_before_date)[PRINCIPAL_RECEIVED]; end
  def interest_received_till_date(on_or_before_date = Date.today); amounts_received_till_date(on_or_before_date)[INTEREST_RECEIVED]; end
  def advance_received_till_date(on_or_before_date = Date.today); amounts_received_till_date(on_or_before_date)[ADVANCE_RECEIVED]; end

  #######################
  # LOAN STATUS QUERIES # begins
  #######################

  # Obtain the current loan status
  def get_current_status; self.status; end

  # Obtain the loan status as on a particular date
  def get_loan_status(on_date)
    #TODO
  end

  #######################
  # LOAN STATUS QUERIES # ends
  #######################

  #########################
  # LOAN DUE STATUS QUERIES # begins
  #########################

  def current_due_status
    #TODO
  end

  def due_status(on_date)
    #TODO
  end

  ###########################
  # LOAN LIFE-CYCLE ACTIONS # begins
  ###########################

  def approve(approved_amount, on_date, approved_by)
    #TODO
  end

  def reject
    #TODO
  end

  def disburse(on_date, with_scheduled_first_repayment_date, to_counterparty_type, to_counterparty_id, by_disbursement_transaction)
    #TODO
    #set disbursed status
    #update first_repayment_date and base schedule, if needed
    #make allocation
    #set loan due status
  end

  def cancel
    #TODO
  end

  def repay(on_date, by_receipt)
    #TODO
  end

  def pre_close
    #TODO
  end

  ###########################
  # LOAN LIFE-CYCLE ACTIONS # ends
  ###########################

  #
  # ALL AT CURRENT POINT IN TIME begins
  #

  def get_current_due_status
    return NOT_DUE if Date.today < self.scheduled_first_repayment_date

    recent_loan_due_status_record = self.loan_due_statuses.most_recent_status_record
    if recent_loan_due_status_record
      recent_loan_due_status           = recent_loan_due_status_record.due_status
      loan_due_status_recorded_on_date = recent_loan_due_status_record.on_date

      #The most recent loan due status is indeed the current status if it was recorded today
      return recent_loan_due_status if (loan_due_status_recorded_on_date == Date.today)

      #The most recent loan due status implies that there has not been any intervening repayments
      #If the loan was already overdue, there is no possibility that it has now improved to due because there are no intervening repayments
      return recent_loan_due_status if (recent_loan_due_status == OVERDUE)
    end

    get_due_status_from_receipts
  end

  #
  # ALL AT CURRENT POINT IN TIME ends
  #

  private

  def self.to_loan(for_amount, repayment_frequency, tenure, from_lending_product, for_borrower_id,
      administered_at_origin, accounted_at_origin, applied_on_date, scheduled_disbursal_date, scheduled_first_repayment_date,
      applied_by_staff, recorded_by_user, lan = nil)
    Validators::Arguments.not_nil?(for_amount, repayment_frequency, tenure, from_lending_product, for_borrower_id,
                                   administered_at_origin, accounted_at_origin, applied_on_date, scheduled_disbursal_date,
                                   scheduled_first_repayment_date, applied_by_staff, recorded_by_user)
    loan_hash                                  = { }
    loan_hash[:applied_amount]                 = for_amount.amount
    loan_hash[:currency]                       = for_amount.currency
    loan_hash[:for_borrower_id]                = for_borrower_id
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
    loan_hash[:lan] = lan if lan
    Lending.new(loan_hash)
  end

  ###########
  # UPDATES # begins
  ###########

  # Set the loan status
  def set_status(new_loan_status, effective_on = Date.today)
    current_status = self.status
    raise Errors::InvalidStateChangeError, "Loan status is already #{new_loan_status}" if current_status == new_loan_status
    self.status = new_loan_status
    raise Errors::DataError, errors.first.first unless save
    LoanStatusChange.record_status_change(self, current_status, new_loan_status, effective_on)
  end

  # All actions required to update the loan for the payment
  def update_for_payment(on_date, payment_transaction)
    #TODO
    #make the allocation
    #record the allocation
    #respond with the allocation
  end

  # Record an allocation on the loan for the given total amount
  def make_allocation(total_amount, on_date = Date.today)
    #TODO
=begin
    if schedule_date?(on_date)
      #allocate to scheduled principal, interest
    else #NOT A SCHEDULE DATE
      if loan is overdue
        #allocate to overdue amounts
      if loan is NOT overdue
        #allocate to advance accumulated
    end
=end
  end

  ###########
  # UPDATES # ends
  ###########

  def get_due_status_from_receipts
    #TODO
  end

  def get_all_balances(on_date)
    # schedule_balances = get_schedule_balances(on_date)
    # also get advances and amounts paid till date
  end

end