class Lending
  include DataMapper::Resource
  include LoanLifeCycle
  include Constants::Money, Constants::Loan, Constants::LoanAmounts, Constants::Properties, Constants::Transaction
  include Validators::Arguments
  include MarkerInterfaces::Recurrence
  include LoanUtility
  include LoanValidations

  after  :create,    :update_cycle_number

  property :id,                             Serial
  property :lan,                            String, :nullable => false
  property :applied_amount,                 *MONEY_AMOUNT_NON_ZERO
  property :currency,                       *CURRENCY
  property :applied_on_date,                *DATE_NOT_NULL
  property :approved_amount,                *MONEY_AMOUNT_NULL
  property :disbursed_amount,               *MONEY_AMOUNT_NULL
  property :scheduled_disbursal_date,       *DATE_NOT_NULL
  property :scheduled_first_repayment_date, *DATE_NOT_NULL
  property :approved_on_date,               *DATE
  property :disbursal_date,                 *DATE
  property :repaid_on_date,                 *DATE
  property :rejected_on_date,               *DATE
  property :write_off_on_date,              *DATE
  property :write_off_approve,              Boolean
  property :write_off_approve_on_date,      *DATE
  property :preclosed_on_date,              *DATE
  property :repayment_frequency,            *FREQUENCY
  property :tenure,                         *TENURE
  property :administered_at_origin,         *INTEGER_NOT_NULL
  property :accounted_at_origin,            *INTEGER_NOT_NULL
  property :applied_by_staff,               *INTEGER_NOT_NULL
  property :approved_by_staff,              Integer
  property :disbursed_by_staff,             Integer
  property :rejected_by_staff,              Integer
  property :written_off_by_staff,           Integer
  property :preclosed_by_staff,             Integer
  property :repaid_by_staff,                Integer
  property :recorded_by_user,               *INTEGER_NOT_NULL
  property :repayment_allocation_strategy,  Enum.send('[]', *LOAN_REPAYMENT_ALLOCATION_STRATEGIES), :nullable => false
  property :status,                         Enum.send('[]', *LOAN_STATUSES), :nullable => false, :default => STATUS_NOT_SPECIFIED
  property :loan_purpose,                   String
  property :created_at,                     *CREATED_AT
  property :updated_at,                     *UPDATED_AT
  property :deleted_at,                     *DELETED_AT
  property :cycle_number,                   Integer, :default => 1, :nullable => false, :index => true
  property :disbursement_mode,              Enum.send('[]', *DISBURSEMENT_MODES), :nullable => false, :default => NOT_SPECIFIED
  property :cheque_number,                  Integer, :nullable => true

  belongs_to :upload, :nullable => true

  if Mfi.first.system_state != :migration
    #validates_with_method :check_working_business_holiday?
  end

  def check_working_business_holiday?
    return_value = true
    loan_dates = {'Apply Date' => self.applied_on_date, 'Approve Date'=>self.approved_on_date, 'Disbursal Date' => self.disbursal_date,
      'Reject Date' => self.rejected_on_date, 'Repaid Date' => self.repaid_on_date, 'Preclose Date' => self.preclosed_on_date,
      'Write Off Date' => self.write_off_on_date
    }
    loan_dates.select{|key,value| !value.blank?}.sort_by{|name,value| value}.each do |date_name, date|
      if !date.blank? && LocationHoliday.working_holiday?(self.administered_at_origin_location, date)
        return return_value = [false, "#{date_name} cannot be Working/Business Holiday"]
      end
    end
    return_value
  end

  def administered_at_origin_location; BizLocation.get(self.administered_at_origin); end
  def accounted_at_origin_location; BizLocation.get(self.accounted_at_origin); end

  def administered_at(on_date)
    LoanAdministration.get_administered_at(self.id, on_date)
  end

  def accounted_at(on_date)
    LoanAdministration.get_accounted_at(self.id, on_date)
  end

  #Increment/sync the loan cycle number. All the past loans which are disbursed are counted
  def update_cycle_number
    client_facade = FacadeFactory.instance.get_instance(FacadeFactory::CLIENT_FACADE, User.first)
    client = self.loan_borrower.counterparty
    loans = client_facade.get_all_loans_for_counterparty(client)
    count = 0
    loans.each do |loan|
      if (loan.id < id and loan.disbursal_date != nil)
        count += 1
      end
    end
    self.cycle_number = count + 1
  end

  # Lists the properties that are money amounts
  def money_amounts
    [:applied_amount, :approved_amount, :disbursed_amount]
  end

  if Mfi.first.system_state != :migration
    validates_with_method *DATE_VALIDATIONS #see app/models/loan_validations.rb
  end
  
  def disbursal_date_value
    self.disbursal_date ? self.disbursal_date : self.scheduled_disbursal_date
  end

  def created_on; self.applied_on_date; end

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
  has n, :loan_claims, 'LoanClaimProcessing'
  has n, :funds_sources

  def delete_loan
    ledger_a = LedgerAssignment.all(:product_id => self.id)
    ledgers = Ledger.all(:ledger_assignment_id => ledger_a.map(&:id))
    ledgers.vouchers.destroy! rescue ''
    ledgers.ledger_postings.destroy! rescue ''
    ledgers.destroy! rescue ''
    ledger_a.destroy! rescue ''

    self.loan_receipts.destroy! rescue ''
    self.loan_due_statuses.destroy! rescue ''
    self.loan_base_schedule.base_schedule_line_items.destroy! rescue ''
    self.loan_base_schedule.destroy! rescue ''
    self.loan_status_changes.destroy! rescue ''
    self.loan_repaid_status.destroy! rescue ''
    self.loan_payments.destroy! rescue ''
    self.loan_claims.destroy! rescue ''
    self.fund_sources.destroy! rescue ''

    PaymentTransaction.all(:on_product_id => self.id).destroy! rescue ''
    LoanBorrower.all(:lending_id => self.id).destroy! rescue ''
    LoanAdministration.all(:loan_id => self.id).destroy! rescue ''
    AccrualTransaction.all(:on_product_id => self.id).destroy! rescue ''
    FundingLineAddition.all(:lending_id => self.id).destroy! rescue ''
    LoanAssignment.all(:loan_id => self.id).destroy! rescue ''
    FeeInstance.all_fee_instances_on_loan(self.id).each{|f| f.destory!} rescue ''
    FeeInstance.all_fee_instances_on_loan_insurance(self.simple_insurance_policies.map(&:id)).each{|f| f.destroy!} rescue ''
    self.simple_insurance_policies.destroy! rescue ''
    self.destroy! rescue ''
  end
  
  def register_loan_claim(for_death_event, on_date)
    Validators::Arguments.not_nil?(for_death_event, on_date)
    raise Errors::BusinessValidationError, "The death event does not affect the borrower on this loan" unless (for_death_event.affected_client == self.borrower)
    raise Errors::BusinessValidationError, "Cannot register a claim on a loan that is not outstanding" unless self.is_outstanding_on_date?(on_date)
    LoanClaimProcessing.register_loan_claim(for_death_event, self, on_date)
  end

  #this method is for upload functionality.
  def self.from_csv(row, headers)
    administered_at_origin = BizLocation.first(:name => row[headers[:center]]).id
    raise ArgumentError, "Center(#{row[headers[:center]]}) does not exist" if administered_at_origin.blank?

    accounted_at_origin = BizLocation.first(:name => row[headers[:branch]]).id
    raise ArgumentError, "Branch(#{row[headers[:branch]]}) does not exist" if accounted_at_origin.blank?

    loan_product = LendingProduct.first(:name => row[headers[:loan_product]])
    lending_product_id = loan_product
    client = Client.first(:name => row[headers[:client]], :upload_reference => row[headers[:upload_reference]])
    loan_borrower_id = client
    funding_line_id = NewFundingLine.first(:reference => row[headers[:funding_line_serial_number]]).id
    tranch_id = NewTranch.first(:reference => row[headers[:tranch_serial_number]]).id
    applied_money_amount = MoneyManager.get_money_instance(row[headers[:applied_amount]])
    approved_money_amount = MoneyManager.get_money_instance(row[headers[:approved_amount]])
    disbursed_money_amount = MoneyManager.get_money_instance(row[headers[:disbursed_amount]])
    applied_amount = applied_money_amount.amount
    currency = applied_money_amount.currency
    approved_amount = approved_money_amount.amount
    disbursed_amount = disbursed_money_amount.amount
    repayment_frequency = row[headers[:repayment_frequency]].downcase.to_sym
    tenure = row[headers[:tenure]]

    applied_on_date = Date.parse(row[headers[:applied_on]])
    approved_on_date = Date.parse(row[headers[:approved_on]])
    scheduled_disbursal_date = Date.parse(row[headers[:scheduled_disbursal_date]])
    scheduled_first_repayment_date = Date.parse(row[headers[:scheduled_first_repayment_date]])
    disbursal_date = Date.parse(row[headers[:disbursal_date]])
    
    applied_by_staff = StaffMember.first(:name => row[headers[:applied_by_staff]]).id
    approved_by_staff = StaffMember.first(:name => row[headers[:approved_by_staff]]).id
    disbursed_by_staff = StaffMember.first(:name => row[headers[:disbursed_by_staff]]).id
    lan = row[headers[:lan]]
    recorded_by_user = User.first.id
    upload_id = row[headers[:upload_id]]

    #creating the loan_borrower entry.
    new_loan_borrower = LoanBorrower.assign_loan_borrower(client, applied_on_date, administered_at_origin, accounted_at_origin,
      applied_by_staff, recorded_by_user)

    #creating new loan.
    loan_hash                                  = { }
    loan_hash[:applied_amount]                 = applied_amount
    loan_hash[:currency]                       = currency
    loan_hash[:repayment_frequency]            = repayment_frequency
    loan_hash[:tenure]                         = tenure
    loan_hash[:lending_product]                = loan_product
    loan_hash[:loan_borrower]                  = new_loan_borrower
    loan_hash[:administered_at_origin]         = administered_at_origin
    loan_hash[:accounted_at_origin]            = accounted_at_origin
    loan_hash[:applied_on_date]                = applied_on_date
    loan_hash[:scheduled_disbursal_date]       = scheduled_disbursal_date
    loan_hash[:scheduled_first_repayment_date] = scheduled_first_repayment_date
    loan_hash[:applied_by_staff]               = applied_by_staff
    loan_hash[:recorded_by_user]               = recorded_by_user
    loan_hash[:lan]                            = lan
    loan_hash[:approved_on_date]               = approved_on_date
    loan_hash[:disbursal_date]                 = disbursal_date
    loan_hash[:approved_by_staff]              = approved_by_staff
    loan_hash[:disbursed_by_staff]             = disbursed_by_staff
    loan_hash[:upload_id]                      = upload_id
    loan_hash[:approved_amount]                = approved_money_amount.amount
    loan_hash[:disbursed_amount]               = disbursed_money_amount.amount
    loan_hash[:repayment_allocation_strategy]  = loan_product.repayment_allocation_strategy
    loan_hash[:status]                         = STATUS_NOT_SPECIFIED

    new_loan = Lending.new(loan_hash)

    total_interest_applicable = loan_product.total_interest_money_amount
    num_of_installments = tenure
    principal_and_interest_amounts = loan_product.amortization
    
    #setting the initial status of loan.
    new_loan.set_status(NEW_LOAN_STATUS, applied_on_date)

    #making enteries in intermediatory models.
    LoanBaseSchedule.create_base_schedule(applied_money_amount, total_interest_applicable, scheduled_disbursal_date, scheduled_first_repayment_date,
      repayment_frequency, num_of_installments, new_loan, principal_and_interest_amounts)

    LoanAdministration.assign(new_loan.administered_at_origin_location, new_loan.accounted_at_origin_location, new_loan, applied_by_staff,
      recorded_by_user, applied_on_date)

    FundingLineAddition.assign_tranch_to_loan(new_loan.id, funding_line_id, tranch_id, new_loan.applied_by_staff, new_loan.applied_on_date,
      recorded_by_user)
  end

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
      funding_line_id,
      tranch_id,
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
    FundingLineAddition.assign_tranch_to_loan(new_loan.id, funding_line_id, tranch_id, new_loan.applied_by_staff, new_loan.applied_on_date, recorded_by_user)
    new_loan
  end

  #############
  # Validations # begins
  #############

  def is_payment_permitted?(payment_transaction)
    transaction_receipt_type = payment_transaction.receipt_type
    transaction_effective_on = payment_transaction.effective_on
    transaction_money_amount = payment_transaction.payment_money_amount
    transaction_towards_type = payment_transaction.payment_towards
    
    Validators::Arguments.not_nil?(transaction_receipt_type, transaction_effective_on, transaction_money_amount)

    #payments
    if transaction_receipt_type == PAYMENT
      return [false, "Loan cannot be disbursed unless approved"] unless self.is_approved?
    end

    #receipts
    if ([RECEIPT, CONTRA].include?(transaction_receipt_type))
      if ([PAYMENT_TOWARDS_LOAN_REPAYMENT, PAYMENT_TOWARDS_LOAN_ADVANCE_ADJUSTMENT, PAYMENT_TOWARDS_LOAN_PRECLOSURE].include?(transaction_towards_type))
        return [false, "Repayments cannot be accepted on loans that are not outstanding"] unless is_outstanding_on_date?(transaction_effective_on)

        maximum_receipt_to_accept = (transaction_receipt_type == CONTRA) ? actual_total_outstanding : actual_total_outstanding_net_advance_balance
        if ((maximum_receipt_to_accept < transaction_money_amount) and Mfi.first.system_state != :migration)
          return [false, "Repayment cannot be accepted on the loan at the moment exceeding #{maximum_receipt_to_accept.to_s}"]
        end
      end
      
      if (transaction_towards_type == PAYMENT_TOWARDS_LOAN_RECOVERY)
        return [false, "Loan recovery is only permitted on written-off loans"] unless is_written_off?

        _maximum_to_be_collected = maximum_to_be_collected
        if (_maximum_to_be_collected < transaction_money_amount)
          return [false, "Recovery cannot exceed #{_maximum_to_be_collected.to_s}"]
        end
      end
    end
    
    true
  end

  def is_payment_transaction_permitted?(money_amount, on_date, for_staff_id, user_id)
    payment_towards = self.is_written_off? ? PAYMENT_TOWARDS_LOAN_RECOVERY : Constants::Transaction::PAYMENT_TOWARDS_LOAN_REPAYMENT
    cp_type      = 'Client'
    cp_id        = self.loan_borrower.counterparty.id
    product_type = self.class.name
    product_id   = self.id
    performed_at = self.administered_at_origin
    accounted_at = self.accounted_at_origin
    performed_by = for_staff_id
    recorded_by  = user_id
    receipt      = 'receipt'
    payment_transaction = PaymentTransaction.new(:amount => money_amount.amount,:currency => 'INR',
      :on_product_type => product_type, :on_product_id => product_id,
      :performed_at => performed_at, :accounted_at => accounted_at,
      :performed_by => performed_by, :recorded_by => recorded_by,
      :by_counterparty_type => cp_type, :by_counterparty_id => cp_id,
      :receipt_type => receipt, :payment_towards => payment_towards, :effective_on => on_date)
    self.is_payment_permitted?(payment_transaction)
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

  def reschedule_installments(first_schedule_date, on_date = Date.today)
    raise ArgumentError, "Effective Date(#{on_date}) cannot Past Date" if on_date < Date.today
    raise ArgumentError, "First Schedule Date(#{first_schedule_date}) cannot Past Date" if first_schedule_date < Date.today
    raise ArgumentError, "Effective Date(#{on_date}) cannot greated then First Schedule Date(#{first_schedule_date})" if first_schedule_date < on_date
    loan_schedules = self.loan_base_schedule.get_schedule_after_date(on_date)
    @updated_date = first_schedule_date
    loan_schedules.each do |schedule|
      schedule.update(:on_date => @updated_date)
      @updated_date = Constants::Time.get_next_date(@updated_date, self.repayment_frequency)
    end
  end

  #######################
  # LOAN SCHEDULE DATES # ends
  #######################

  ############
  # Borrower # begins
  ############

  # Gets the instance of borrower
  def borrower; self.loan_borrower ? self.loan_borrower.counterparty : nil; end

  def counterparty; self.borrower; end

  def borrower_caste; (self.loan_borrower and self.loan_borrower.counterparty and (not self.loan_borrower.counterparty.nil?)) ? self.loan_borrower.counterparty.caste : nil; end

  def borrower_religion; (self.loan_borrower and self.loan_borrower.counterparty and (not self.loan_borrower.counterparty.nil?)) ? self.loan_borrower.counterparty.religion : nil; end

  def borrower_town_classification; (self.loan_borrower and self.loan_borrower.counterparty and (not self.loan_borrower.counterparty.nil?)) ? self.loan_borrower.counterparty.town_classification : nil; end

  def borrower_psl; (self.loan_borrower and self.loan_borrower.counterparty and (not self.loan_borrower.counterparty.nil?) and (not self.loan_borrower.counterparty.priority_sector_list_id.nil?)) ? self.loan_borrower.counterparty.priority_sector_list_id : nil; end

  ############
  # Borrower # ends
  ############

  ################
  # LOAN AMOUNTS # begins
  ################

  # TODO on loan amounts
  # TOTAL_LOAN_DISBURSED amount to be calculated on the basis of disbursements from payments
  # TOTAL_INTEREST_APPLICABLE amount to be (re)calculated whenever there is a disbursement

  def self.total_loans_between_dates(status = nil, from_date = Date.today, to_date = Date.today)
    status_key = status.blank? ? '' : LoanLifeCycle::LOAN_STATUSES.index(status.to_sym)
    if status_key.blank?
      l_status = repository(:default).adapter.query("select a.lending_id, a.to_status from loan_status_changes a where (a.to_status, a.lending_id) = (select b.to_status,b.lending_id from loan_status_changes b where b.lending_id = a.lending_id and (b.effective_on >= '#{from_date.strftime("%Y-%m-%d")}' or b.effective_on <= '#{to_date.strftime("%Y-%m-%d")}') order by b.effective_on desc limit 1 );")
      l_status.blank? ? {} : l_status.group_by{|s| s.to_status}
    else
      repository(:default).adapter.query("select lending_id from loan_status_changes a where a.to_status = #{status_key+1} and (a.to_status, a.lending_id) = (select b.to_status,b.lending_id from loan_status_changes b where b.lending_id = a.lending_id and (b.effective_on >= '#{from_date.strftime("%Y-%m-%d")}' or b.effective_on <= '#{to_date.strftime("%Y-%m-%d")}') order by b.effective_on desc limit 1 );")
    end
  end
  # The total loan amount disbursed
  def total_loan_disbursed
    self.loan_payments.sum_till_date || zero_money_amount
  end

  # The total interest applicable as computed at the time that the loan was disbursed
  def total_interest_applicable
    raise Errors::InitialisationNotCompleteError, "A loan base schedule is not currently available for the loan" unless self.loan_base_schedule
    self.loan_base_schedule.total_interest_applicable_money_amount
  end

  def total_loan_disbursed_and_interest_applicable
    (total_loan_disbursed || zero_money_amount) + (total_interest_applicable || zero_money_amount)
  end

  def maximum_to_be_collected
    (total_loan_disbursed_and_interest_applicable > total_received_till_date) ? (total_loan_disbursed_and_interest_applicable - total_received_till_date) :
      zero_money_amount
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

  def actual_principal_outstanding(on_date = Date.today)
    return zero_money_amount unless is_outstanding_on_date?(on_date)

    if (total_loan_disbursed > principal_received_till_date(on_date))
      return (total_loan_disbursed - principal_received_till_date(on_date))
    end
    zero_money_amount
  end

  def actual_interest_outstanding(on_date = Date.today)
    return zero_money_amount unless is_outstanding_on_date?(on_date)

    if (total_interest_applicable > interest_received_till_date(on_date))
      return (total_interest_applicable - interest_received_till_date(on_date))
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

  def actual_total_due_ignoring_advance_balance(on_date)
    _scheduled_total_outstanding = scheduled_total_outstanding(on_date)
    _actual_total_outstanding    = actual_total_outstanding

    (_actual_total_outstanding > _scheduled_total_outstanding) ? (_actual_total_outstanding - _scheduled_total_outstanding) :
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

  def accrued_interim_interest(from_date, to_date)
    return zero_money_amount if from_date == to_date
    raise ArgumentError, "The from date: #{from_date} must precede to date: #{to_date}" if from_date > to_date
    scheduled_interest_outstanding_from_date = scheduled_interest_outstanding(from_date)
    most_recent_schedule_date = Constants::Time.get_immediately_earlier_date(to_date, *schedule_dates)
    recent_scheduled_interest_outstanding = scheduled_interest_outstanding(most_recent_schedule_date)
    scheduled_interest_outstanding_from_date > recent_scheduled_interest_outstanding ? (scheduled_interest_outstanding_from_date - recent_scheduled_interest_outstanding) : zero_money_amount
  end

  def interest_for_preclose(to_date)
    scheduled_amount_till_date  = get_sum_scheduled_amounts_info_till_date(to_date)
    scheduled_received_interest = scheduled_amount_till_date[:sum_of_scheduled_interest_due]
    received_interest_till_date = interest_received_till_date(to_date)
    interest                    = scheduled_received_interest > received_interest_till_date ? scheduled_received_interest-received_interest_till_date : MoneyManager.default_zero_money
    interest                    += broken_period_interest_due(to_date) unless schedule_dates.include?(to_date)
    interest
  end

  def broken_period_interest_due(on_date)
    return zero_money_amount unless (self.disbursal_date and on_date > self.disbursal_date)
    return zero_money_amount if schedule_date?(on_date)
    return zero_money_amount if on_date >= last_scheduled_date

    previous_schedule_date = Constants::Time.get_immediately_earlier_date(on_date, *schedule_dates)
    next_schedule_date = Constants::Time.get_immediately_next_date(on_date, *schedule_dates)

    ios_earlier = scheduled_interest_outstanding(previous_schedule_date)
    ios_later = scheduled_interest_outstanding(next_schedule_date)

    Allocation::Common.calculate_broken_period_interest(ios_earlier, ios_later, previous_schedule_date, next_schedule_date, on_date, self.repayment_frequency)
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

  def get_sum_scheduled_amounts_info_till_date(on_date)
    sum_of_scheduled_principal_due = sum_of_scheduled_interest_due = zero_money_amount
    unless (on_date < scheduled_first_repayment_date)
      line_items = loan_base_schedule.base_schedule_line_items.all(:on_date.lte => on_date)
      line_items.each do |value|
        installment_no = value.installment
        if installment_no > 0
          sum_of_scheduled_principal_due += value.to_money[:scheduled_principal_due]
          sum_of_scheduled_interest_due += value.to_money[:scheduled_interest_due]
        end
      end
    end
    {:sum_of_scheduled_principal_due => sum_of_scheduled_principal_due, :sum_of_scheduled_interest_due => sum_of_scheduled_interest_due}
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

  def unpaid_loan_insurance_fees
    policies = self.simple_insurance_policies
    fee_instances = []
    policies.each{|policy| fee_instances << FeeInstance.get_unpaid_fees_for_instance(policy)}
    fee_instances.flatten
  end

  def get_preclosure_penalty_product
    FeeAdministration.get_preclosure_penalty_fee_products(self.lending_product).first
    # SimpleFeeProduct.get_applicable_preclosure_penalty(self.lending_product_id)
  end

  ########
  # Fees # ends
  ########

  ########################################################
  # LOAN PAYMENTS, RECEIPTS, ADVANCES, ALLOCATION  QUERIES # begins
  ########################################################

  def current_advance_available
    advance_balance
  end

  def historical_advance_available(on_date)
    # TODO implement using accounting facade
    advance_received_till_date(on_date) - advance_adjusted_till_date(on_date)
  end

  def amounts_received_on_date(on_date = Date.today)
    self.loan_receipts.sum_on_date(on_date)
  end

  def principal_received_on_date(on_date = Date.today); amounts_received_on_date(on_date)[PRINCIPAL_RECEIVED]; end
  def interest_received_on_date(on_date = Date.today); amounts_received_on_date(on_date)[INTEREST_RECEIVED]; end
  def advance_received_on_date(on_date = Date.today); amounts_received_on_date(on_date)[ADVANCE_RECEIVED]; end
  def advance_adjusted_on_date(on_date = Date.today); amounts_received_on_date(on_date)[ADVANCE_ADJUSTED]; end
  def loan_recovery_on_date(on_date = Date.today); amounts_received_on_date(on_date)[LOAN_RECOVERY]; end

  def total_received_on_date(on_date = Date.today)
    principal_received_on_date(on_date) + interest_received_on_date(on_date) + advance_received_on_date(on_date)
  end

  def amounts_received_till_date(on_date = Date.today)
    historical_amounts_received_till_date(on_date)
  end

  def amounts_received_between_dates(from_date = Date.today, to_date = Date.today)
    historical_amounts_received_between_dates(from_date, to_date)
  end

  def historical_amounts_received_till_date(on_or_before_date)
    self.loan_receipts.sum_till_date(on_or_before_date)
  end

  def historical_amounts_received_between_dates(from_date = Date.today, to_date = Date.today)
    self.loan_receipts.sum_between_dates(from_date, to_date)
  end

  def principal_received_till_date(on_date = Date.today); amounts_received_till_date(on_date)[PRINCIPAL_RECEIVED]; end
  def interest_received_till_date(on_date = Date.today); amounts_received_till_date(on_date)[INTEREST_RECEIVED]; end
  def advance_received_till_date(on_date = Date.today); amounts_received_till_date(on_date)[ADVANCE_RECEIVED]; end
  def advance_adjusted_till_date(on_date = Date.today); amounts_received_till_date(on_date)[ADVANCE_ADJUSTED]; end
  def loan_recovery_till_date(on_date = Date.today); amounts_received_till_date(on_date)[LOAN_RECOVERY]; end

  def total_received_till_date
    principal_received_till_date + interest_received_till_date + advance_balance + loan_recovery_till_date
  end

  def principal_received_in_date_range(from_date = Date.today, to_date = from_date)
    principal_received_on_from_date = amounts_received_till_date(from_date)[PRINCIPAL_RECEIVED]
    principal_received_on_to_date = amounts_received_till_date(to_date)[PRINCIPAL_RECEIVED] 
    if principal_received_on_from_date > principal_received_on_to_date 
      principal_received_during_date_range = principal_received_on_from_date - principal_received_on_to_date
    else
      principal_received_during_date_range = principal_received_on_to_date - principal_received_on_from_date
    end
    principal_received_during_date_range
  end

  def interest_received_in_date_range(from_date = Date.today, to_date = from_date)
    interest_received_on_from_date = amounts_received_till_date(from_date)[INTEREST_RECEIVED]
    interest_received_on_to_date = amounts_received_till_date(to_date)[INTEREST_RECEIVED] 
    if interest_received_on_from_date > interest_received_on_to_date 
      interest_received_during_date_range = interest_received_on_from_date - interest_received_on_to_date
    else
      interest_received_during_date_range = interest_received_on_to_date - interest_received_on_from_date
    end
    interest_received_during_date_range
  end

  def advance_balance(on_date = Date.today)
    receipt_amounts = LoanReceipt.sum_till_date_for_loans(self.id, on_date)
    receipt_amounts[ADVANCE_RECEIVED] - receipt_amounts[ADVANCE_ADJUSTED]
  end

  def overdue_amount(on_date)
    return zero_money_amount unless (self.disbursal_date and on_date > self.disbursal_date)
    schedule_amount_till_date = get_sum_scheduled_amounts_info_till_date(on_date)
    line_item                 = loan_base_schedule.base_schedule_line_items.first(:on_date => on_date)
    schedule_amount_on_date   = line_item.blank? ? zero_money_amount : line_item.to_money[:scheduled_principal_due]+line_item.to_money[:scheduled_interest_due]
    amount_till_date          = schedule_amount_till_date[:sum_of_scheduled_principal_due]+schedule_amount_till_date[:sum_of_scheduled_interest_due]
    received_till_date        = amounts_received_till_date(on_date)[:total_received]
    return zero_money_amount if amount_till_date < received_till_date
    overdue_on_date = amount_till_date-received_till_date
    received_till_date > amount_till_date || overdue_on_date < schedule_amount_on_date ? zero_money_amount : overdue_on_date-schedule_amount_on_date
  end

  ########################################################
  # LOAN PAYMENTS, RECEIPTS, ADVANCES, ALLOCATION  QUERIES # ends
  ########################################################

  #######################
  # LOAN STATUS QUERIES # begins
  #######################

  # Obtain the loan status as on a particular date
  def historical_loan_status_on_date(on_date)
    status_in_force_on_date = self.loan_status_changes.status_in_force(on_date)
    raise Errors::InvalidOperationError, "A loan status cannot be requested on the date: #{on_date}" unless status_in_force_on_date
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
    unless(schedule_date?(on_date))
      (actual_total_outstanding_net_advance_balance >= sum_of_outstanding_and_due_total(on_date)) ? OVERDUE : DUE
    else
      (actual_total_outstanding_net_advance_balance > sum_of_outstanding_and_due_total(on_date)) ? OVERDUE : DUE
    end
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

  def loan_days_past_due(on_date = Date.today)
    days_past_due_till_date = self.loan_due_statuses(:fields => [:id, :due_status], :on_date.lte => on_date, :order => [:id.desc])
    return 0 if days_past_due_till_date.empty?

    days_past_due_on_date = days_past_due_till_date.first
    return 0 unless days_past_due_on_date.is_overdue?
    unbroken_days_past_due = 0
    days_past_due_till_date.each { |due_status_record|
      if due_status_record.is_overdue?
        unbroken_days_past_due += 1
      else
        break
      end
    }
    unbroken_days_past_due
  end

  #this method is same as days_past_due_on_date with a small modification.
  def days_past_dues_on_date(on_date)
    if self.disbursal_date < on_date
      return 0 unless is_outstanding_on_date?(on_date)
      LoanDueStatus.unbroken_days_past_due(self.id, on_date)
    else
      return 0
    end
  end

  ###########################
  # LOAN LIFE-CYCLE ACTIONS # begins
  ###########################

  def allocate_payment(payment_transaction, loan_action, make_specific_allocation = false, specific_principal_amount = nil, specific_interest_amount = nil, fee_instance_id = nil, adjust_complete_advance = false)
    if Mfi.first.system_state != :migration
      is_transaction_permitted_val = is_payment_permitted?(payment_transaction)

      is_transaction_permitted, error_message = is_transaction_permitted_val.is_a?(Array) ? [is_transaction_permitted_val.first, is_transaction_permitted_val.last] :
        [true, nil]
      raise Errors::BusinessValidationError, error_message unless is_transaction_permitted

      if (make_specific_allocation)
        raise ArgumentError, "A principal and interest amount to allocate must be specified" unless (specific_principal_amount and specific_interest_amount)

        total_principal_and_interest = specific_principal_amount + specific_interest_amount
        if (total_principal_and_interest > actual_total_outstanding_net_advance_balance)
          raise Errors::BusinessValidationError, "Total principal and interest amount to allocate cannot exceed loan amount outstanding"
        end
      end
    end

    allocation = nil
    @adjust_complete_advance = adjust_complete_advance
    case loan_action
    when LOAN_DISBURSEMENT then allocation = disburse(payment_transaction)
    when LOAN_REPAYMENT then allocation = repay(payment_transaction)
    when LOAN_PRECLOSURE then allocation = preclose(payment_transaction, specific_principal_amount, specific_interest_amount)
    when LOAN_ADVANCE_ADJUSTMENT then allocation = adjust_advance(payment_transaction)
    when LOAN_RECOVERY then allocation = recover_on_loan(payment_transaction)
    when LOAN_FEE_RECEIPT then allocation = fee_payment_on_loan(payment_transaction, fee_instance_id)
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
      if ([LOAN_ADVANCE_ADJUSTMENT, LOAN_REPAYMENT].include?(loan_action))
        if (actual_total_outstanding == zero_money_amount)
          repaid_nature = LoanLifeCycle::REPAYMENT_ACTIONS_AND_REPAID_NATURES[loan_action]
          raise Errors::BusinessValidationError, "Repaid nature not configured for loan action: #{loan_action}" unless repaid_nature
          mark_loan_repaid(repaid_nature, payment_transaction.effective_on, payment_transaction.performed_by, actual_principal_outstanding, actual_interest_outstanding)
        end
      elsif loan_action == LOAN_PRECLOSURE
        repaid_nature = LoanLifeCycle::REPAYMENT_ACTIONS_AND_REPAID_NATURES[loan_action]
        raise Errors::BusinessValidationError, "Repaid nature not configured for loan action: #{loan_action}" unless repaid_nature
        mark_loan_repaid(repaid_nature, payment_transaction.effective_on, payment_transaction.performed_by, actual_principal_outstanding, actual_interest_outstanding)
      end
    end
  end

  def mark_loan_repaid(repaid_nature, on_date, by_staff, closing_principal_outstanding, closing_interest_outstanding)
    self.loan_repaid_status = LoanRepaidStatus.to_loan_repaid_status(self, repaid_nature, on_date, closing_principal_outstanding, closing_interest_outstanding)
    if repaid_nature == PRECLOSED
      self.preclosed_on_date  = on_date
      self.preclosed_by_staff = by_staff
      status                  = PRECLOSED_LOAN_STATUS
    else
      self.repaid_on_date  = on_date
      self.repaid_by_staff = by_staff
      status               = REPAID_LOAN_STATUS
    end
    set_status(status, on_date)
  end

  def approve(approved_amount, approved_on_date, approved_by)
    #disabled validations in migration mode.
    if Mfi.first.system_state != :migration
      Validators::Arguments.not_nil?(approved_amount, approved_on_date, approved_by)
      raise Errors::BusinessValidationError, "approved amount #{approved_amount.to_s} cannot exceed applied amount #{to_money_amount(self.applied_amount)}" if approved_amount.amount > self.applied_amount
      raise Errors::BusinessValidationError, "approved on date: #{approved_on_date} cannot precede the applied on date #{applied_on_date}" if approved_on_date < applied_on_date
      raise Errors::InvalidStateChangeError, "Only a new loan can be approved" unless current_loan_status == NEW_LOAN_STATUS
    end
    self.approved_amount   = approved_amount.amount
    self.approved_on_date  = approved_on_date
    self.approved_by_staff = approved_by
    set_status(APPROVED_LOAN_STATUS, approved_on_date)
    setup_on_approval
  end

  def reject(rejected_on_date, rejected_by)
    Validators::Arguments.not_nil?(rejected_on_date, rejected_by)
    raise Errors::BusinessValidationError, "reject on date: #{rejected_on_date} cannot precede the applied on date #{applied_on_date}" if rejected_on_date < applied_on_date
    raise Errors::InvalidStateChangeError, "Only a new and approve loan can be reject" unless [NEW_LOAN_STATUS, APPROVED_LOAN_STATUS].include?(current_loan_status)

    self.rejected_on_date  = rejected_on_date
    self.rejected_by_staff = rejected_by
    set_status(REJECTED_LOAN_STATUS, rejected_on_date)
  end

  def write_off(write_off_on_date, written_off_by_staff)
    Validators::Arguments.not_nil?(write_off_on_date, written_off_by_staff)
    Validators::Arguments.is_id?(written_off_by_staff)
    raise Errors::BusinessValidationError, "A loan cannot be written off on a future date: #{write_off_on_date}" if (Date.today < write_off_on_date)
    raise Errors::InvalidStateChangeError, "Only a loan that is outstanding can be written off" unless self.is_outstanding?

    self.write_off_on_date    = write_off_on_date
    self.written_off_by_staff = written_off_by_staff
    set_status(WRITTEN_OFF_LOAN_STATUS, write_off_on_date)
    bk = MyBookKeeper.new
    total_loan_disbursed = self.to_money[:disbursed_amount]
    total_principal_received = self.principal_received_till_date(write_off_on_date)
    write_off_on_amount = total_loan_disbursed - total_principal_received
    bk.account_for_write_off(self, {:total_received => write_off_on_amount}, write_off_on_date)
    bk.account_for_accrual_reverse(self, write_off_on_date)
  end

  def setup_on_approval
    setup_fee_instances
    setup_insurance_policies
    setup_product_accounting
  end

  def setup_product_accounting
    accounts_chart_for_borrower = AccountsChart.get_counterparty_accounts_chart(self.borrower)
    ledger_base_currency = self.currency
    ledger_open_date = self.borrower.created_on
    Ledger.setup_product_ledgers(accounts_chart_for_borrower, ledger_base_currency, ledger_open_date, Constants::Products::LENDING, self.id)
  end

  def setup_fee_instances
    loan_fee_product_map = get_loan_fee_product
    unless loan_fee_product_map.blank?
      loan_fee_product_map.each {|loan_fee_product_instance|
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
    if Mfi.first.system_state == :migration
      on_disbursal_date = by_disbursement_transaction.effective_on
      self.disbursed_amount   = by_disbursement_transaction.amount
      self.disbursal_date     = on_disbursal_date
      self.disbursed_by_staff = by_disbursement_transaction.performed_by
      set_status(DISBURSED_LOAN_STATUS, on_disbursal_date)
      disbursement_money_amount = by_disbursement_transaction.payment_money_amount
      LoanPayment.record_loan_payment(disbursement_money_amount, self, on_disbursal_date)
      disbursement_allocation = {LOAN_DISBURSED => by_disbursement_transaction.payment_money_amount}
      disbursement_allocation = Money.add_total_to_map(disbursement_allocation, TOTAL_PAID)
      disbursement_allocation
    else
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
  end

  def repay(by_receipt)
    update_for_payment(by_receipt)
  end

  def preclose(by_receipt, principal_money_amount, interest_money_amount)
    make_specific_allocation = true
    update_for_payment(by_receipt, make_specific_allocation, principal_money_amount, interest_money_amount)
  end

  def adjust_advance(by_contra)
    make_specific_allocation = false; specific_principal_money_amount = nil; specific_interest_money_amount = nil
    adjust_advance = true
    update_for_payment(by_contra, make_specific_allocation, specific_principal_money_amount, specific_interest_money_amount, adjust_advance)
  end

  def recover_on_loan(by_receipt)
    make_specific_allocation = false; specific_principal_money_amount = nil; specific_interest_money_amount = nil
    adjust_advance = false; recover_on_loan = true
    update_for_payment(by_receipt, make_specific_allocation, specific_principal_money_amount, specific_interest_money_amount, adjust_advance, recover_on_loan)
  end

  def fee_payment_on_loan(by_receipt, fee_instance_id)
    make_specific_allocation = false; specific_principal_money_amount = nil; specific_interest_money_amount = nil
    adjust_advance = false; recover_on_loan = true
    update_for_payment(by_receipt, make_specific_allocation, specific_principal_money_amount, specific_interest_money_amount, adjust_advance, recover_on_loan, fee_instance_id)
  end

  ###########################
  # LOAN LIFE-CYCLE ACTIONS # ends
  ###########################

  ###########
  #
  # UPDATES # begins
  ###########

  # Set the loan status
  def set_status(new_loan_status, effective_on)
    current_status = self.status
    raise Errors::InvalidStateChangeError, "Loan status is already #{new_loan_status}" if current_status == new_loan_status
    self.status = new_loan_status
    if Mfi.first.system_state != :migration
      loan_product_identifier = LendingProduct.get_loan_product_identifier(self.lending_product_id)
      branch_identifier = BizLocation.get_biz_location_identifier(self.accounted_at_origin)
      lan_id = "%.6i"%Lending.get_lan_identifier
      self.lan = "LN-#{loan_product_identifier}-#{branch_identifier}-#{lan_id}"
    end
    raise Errors::DataError, self.errors.first.first unless self.save
    
    LoanStatusChange.record_status_change(self, current_status, new_loan_status, effective_on)
  end

  # Fetch all the loans to update funding lines
  # Eligible loans criteria:
  # 1. loan should be never encumbered or never securitised
  # 2. loan borrower mush not be inactive(under claim processing)
  # 3. loan must not be written-off, preclosed, rejected, cancelled.
  # 4. loan must have outstanding
  # 5. loan must have minimum 3 repayments recieved
  def self.loans_eligible_for_sec_or_encum(center_id)
    loan_assignment_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOAN_ASSIGNMENT_FACADE, User.first)
    eligible_loans = []
    loans = LoanAdministration.get_loans_administered(center_id)
    loans.each do |loan|
      loan_assignment = loan_assignment_facade.get_loan_assigned_to(loan.id, Date.today)
      unless loan_assignment.blank?
        no_assignments = !(loan_assignment.is_additional_encumbered) ? false : true
      else
        no_assignments = true
      end
      client = Client.get(loan.loan_borrower.counterparty_id)
      is_active = !Client.is_claim_processing_or_inactive?(client)
      has_3_minimum_repayments = loan.loan_receipts.size >= 3 ? true : false
      eligible = no_assignments && loan.is_outstanding? && is_active && has_3_minimum_repayments ? true : false
      eligible_loans << loan if eligible == true
    end
    eligible_loans
  end

  def self.is_loan_eligible_for_loan_assignments?(loan_id)
    loan_assignment_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOAN_ASSIGNMENT_FACADE, User.first)
    loan_assignment = loan_assignment_facade.get_loan_assigned_to(loan_id, Date.today)
    loan = Lending.get loan_id
    client = Client.get(loan.loan_borrower.counterparty_id)
    msg = "Ineligible Loan for assignment"
    if Client.is_claim_processing_or_inactive?(client)
      return [false, msg+" (Client is under claim processing)"]
    end
    unless loan_assignment.blank? 
      if !(loan_assignment.is_additional_encumbered)
        return [false, msg+" (Loan is already assigned)"]
      end
    end
    unless loan.is_outstanding?
      return [false, msg+" (Loan does not have outstanding)"]
    end
    true
  end

  def update_loan_shechdule_according_calendar_holiday(on_date, move_date, after_date = Date.today)
    on_date = on_date.class == Date ? on_date : Date.parse(on_date)
    move_date = move_date.class == Date ? move_date : Date.parse(move_date)
    after_date = after_date.class == Date ? after_date : Date.parse(after_date)
    loan_schedules = self.loan_base_schedule.get_schedule_after_date(after_date)
    schedules = loan_schedules.select{|s| s.on_date == on_date}
    schedules.each{|schedule| schedule.update(:on_date => move_date)}
  end

  def self.get_lan_identifier
    Lending.last.blank? ? 1 : (Lending.last.lan.split("-").last).to_i + 1
  end

  def self.update_lan_for_existing_loans
    all_loans = Lending.all(:fields => [:id,:lending_product_id, :accounted_at_origin])
    lan_id_code = 1
    all_loans.each do |loan|
      loan_product_identifier = LendingProduct.get_loan_product_identifier(loan.lending_product_id)
      branch_identifier = BizLocation.get_biz_location_identifier(loan.accounted_at_origin)
      lan_id = "%.6i"%lan_id_code
      loan.lan = "LN-#{loan_product_identifier}-#{branch_identifier}-#{lan_id}"
      lan_id_code += 1
      loan.save!
    end
  end

  def self.tag_write_off_loan
    funders = NewFunder.all(:name => ['WRITE-OFF-2', 'WRITE-OFF'])
    staff_id = StaffMember.first.id
    funders.each do |funder|
      write_off_date = funder.name == 'WRITE-OFF-2' ? Date.new(2011,12,31) : Date.new(2011,03,31)
      funding_lines = funder.new_funding_lines
      funding_lines.each do |funding_line|
        loan_ids = FundingLineAddition.all(:funding_line_id => funding_line.id).aggregate(:lending_id)
        loan_ids.each do |loan_id|
          loan = Lending.get loan_id
          loan.update(:write_off_approve_on_date => write_off_date, :write_off_approve => true)
          loan.write_off(write_off_date, staff_id)
        end
      end
    end
  end
  
  private

  def get_loan_fee_product
    FeeAdministration.get_fee_products(self.lending_product)
    #SimpleFeeProduct.get_applicable_fee_products_on_loan_product(self.lending_product.id)
  end

  def get_insurance_products_and_premia
    insurance_products_and_premia = {}
    insurance_products_on_loan = self.lending_product.simple_insurance_products
    insurance_products_on_loan.each { |insurance_product|
      premium_map = SimpleFeeProduct.get_applicable_premium_on_insurance_product(insurance_product.id)
      premium_fee_product = premium_map[Constants::Transaction::PREMIUM_COLLECTED_ON_INSURANCE]
      raise Errors::InvalidConfigurationError, "An insurance premium has not been configured for the insurance product: #{insurance_product.name}" unless premium_fee_product
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
  def update_for_payment(payment_transaction, make_specific_allocation = false, specific_principal_money_amount = nil, specific_interest_money_amount = nil, adjust_advance = false, recover_on_loan = false, fee_instance_id = nil)
    payment_amount = payment_transaction.payment_money_amount
    effective_on = payment_transaction.effective_on
    performed_at = payment_transaction.performed_at
    accounted_at = payment_transaction.accounted_at
    performed_by = payment_transaction.performed_by
    recorded_by  = payment_transaction.recorded_by
    payment_allocation = make_allocation(payment_amount, effective_on, make_specific_allocation, specific_principal_money_amount, specific_interest_money_amount, adjust_advance, recover_on_loan)
    if payment_transaction.product_action == LOAN_FEE_RECEIPT
      fee_instance = FeeInstance.get(fee_instance_id)
      fee_receipt = FeeReceipt.record_fee_receipt(fee_instance, payment_amount, effective_on, performed_by, recorded_by) unless fee_instance.blank?
    else
      loan_receipt = LoanReceipt.record_allocation_as_loan_receipt(payment_transaction, payment_allocation, performed_at, accounted_at, self, effective_on)
    end
    
    payment_allocation
  end

  def init_allocation
    {
      PRINCIPAL_RECEIVED => zero_money_amount,
      INTEREST_RECEIVED  => zero_money_amount,
      ADVANCE_RECEIVED   => zero_money_amount,
      ADVANCE_ADJUSTED   => zero_money_amount,
      LOAN_RECOVERY      => zero_money_amount
    }
  end

  # Record an allocation on the loan for the given total amount
  def make_allocation(total_amount, on_date, make_specific_allocation = false, specific_principal_money_amount = nil, specific_interest_money_amount = nil, adjust_advance = false, recover_on_loan = false)
    raise ArgumentError, "Cannot allocate zero amount" unless (total_amount > zero_money_amount)

    resulting_allocation = init_allocation

    if (recover_on_loan)
      resulting_allocation[LOAN_RECOVERY] = total_amount
      return Money.add_total_to_map(resulting_allocation, TOTAL_RECEIVED)
    end

    if (make_specific_allocation)
      raise ArgumentError, "Specific principal amount was not available" unless (specific_principal_money_amount and (specific_principal_money_amount.is_a?(Money)))
      raise ArgumentError, "Specific interest amount was not available" unless (specific_interest_money_amount and (specific_interest_money_amount.is_a?(Money)))

      resulting_allocation[PRINCIPAL_RECEIVED] = specific_principal_money_amount
      resulting_allocation[INTEREST_RECEIVED]  = specific_interest_money_amount
      return Money.add_total_to_map(resulting_allocation, TOTAL_RECEIVED)
    end

    _current_due_status = (on_date < self.scheduled_first_repayment_date) ? NOT_DUE : current_due_status

    #allocate when not due
    unless (adjust_advance)
      if (_current_due_status == NOT_DUE)
        resulting_allocation[ADVANCE_RECEIVED] = total_amount
        return Money.add_total_to_map(resulting_allocation, TOTAL_RECEIVED)
      end
    end

    #TODO handle scenario where repayment is received between schedule dates
    if @adjust_complete_advance == true
      principal_due = self.actual_principal_outstanding
      interest = total_amount >= principal_due ? total_amount-principal_due : zero_money_amount
      principal = total_amount >= principal_due ? total_amount-interest : total_amount
      resulting_allocation[PRINCIPAL_RECEIVED] = principal
      resulting_allocation[INTEREST_RECEIVED]  = interest
      resulting_allocation[ADVANCE_ADJUSTED] = total_amount
    else
      _actual_total_due = adjust_advance ? self.actual_total_due_ignoring_advance_balance(on_date) : self.actual_total_due(on_date)
       
      only_principal_and_interest = [_actual_total_due, total_amount].min

      advance_to_allocate = zero_money_amount
      unless adjust_advance
        advance_to_allocate = (total_amount > only_principal_and_interest) ?
          (total_amount - only_principal_and_interest) : zero_money_amount
      end

      fresh_allocation = allocate_principal_and_interest(only_principal_and_interest, on_date)

      resulting_allocation[PRINCIPAL_RECEIVED] = fresh_allocation[:principal]
      resulting_allocation[INTEREST_RECEIVED]  = fresh_allocation[:interest]
      total_principal_and_interest_allocated   = fresh_allocation[:principal] + fresh_allocation[:interest]

      advance_to_allocate += fresh_allocation[:amount_not_allocated] unless adjust_advance
      resulting_allocation[ADVANCE_RECEIVED] = advance_to_allocate
    
      advance_adjusted = adjust_advance ? total_principal_and_interest_allocated : zero_money_amount
      resulting_allocation[ADVANCE_ADJUSTED] = advance_adjusted
    end
    Money.add_total_to_map(resulting_allocation, TOTAL_RECEIVED)
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
    else
      Lending.all(:conditions => ["lan=? or lan like ?", q, q+'%'], :limit => per_page)
    end
  end

  ##########
  # Search # ends
  ##########

end