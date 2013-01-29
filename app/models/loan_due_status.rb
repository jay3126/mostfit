class LoanDueStatus
  include DataMapper::Resource
  include Constants::Properties, Constants::Loan, Constants::LoanAmounts, LoanLifeCycle
  include Comparable
  
  property :id,                             Serial
  property :loan_status,                    Enum.send('[]', *LOAN_STATUSES), :nullable => false
  property :due_status,                     Enum.send('[]', *LOAN_DUE_STATUSES), :nullable => false
  property :administered_at,                *INTEGER_NOT_NULL
  property :accounted_at,                   *INTEGER_NOT_NULL
  property :on_date,                        *DATE_NOT_NULL
  property :has_loan_claim,                 Boolean, :default => false
  property :has_loan_claim_since,           *DATE
  property SCHEDULED_PRINCIPAL_OUTSTANDING, *MONEY_AMOUNT
  property SCHEDULED_INTEREST_OUTSTANDING,  *MONEY_AMOUNT
  property SCHEDULED_TOTAL_OUTSTANDING,     *MONEY_AMOUNT
  property SCHEDULED_PRINCIPAL_DUE,         *MONEY_AMOUNT
  property SCHEDULED_INTEREST_DUE,          *MONEY_AMOUNT
  property SCHEDULED_TOTAL_DUE,             *MONEY_AMOUNT
  property ACTUAL_PRINCIPAL_OUTSTANDING,    *MONEY_AMOUNT
  property PRINCIPAL_AT_RISK,               *MONEY_AMOUNT
  property ACTUAL_INTEREST_OUTSTANDING,     *MONEY_AMOUNT
  property ACTUAL_TOTAL_OUTSTANDING,        *MONEY_AMOUNT
  property ACTUAL_TOTAL_DUE,                *MONEY_AMOUNT
  property :principal_received_on_date,     *MONEY_AMOUNT
  property :interest_received_on_date,      *MONEY_AMOUNT
  property :principal_received_till_date,   *MONEY_AMOUNT
  property :interest_received_till_date,    *MONEY_AMOUNT
  property :advance_received_on_date,       *MONEY_AMOUNT
  property :advance_adjusted_on_date,       *MONEY_AMOUNT
  property :advance_received_till_date,     *MONEY_AMOUNT
  property :advance_adjusted_till_date,     *MONEY_AMOUNT
  property :advance_balance,                *MONEY_AMOUNT
  property :interest_accrual_till_date,     *MONEY_AMOUNT
  property :currency,                       *CURRENCY
  property :day_past_due,                   Integer, :default => 0
  property :created_at,                     *CREATED_AT

  belongs_to :lending

  def administered_at_location; BizLocation.get(self.administered_at); end
  def accounted_at_location; BizLocation.get(self.accounted_at); end

  def <=>(other)
    return nil unless other.is_a?(LoanDueStatus)
    compare_on_date = other.on_date <=> self.on_date
    (compare_on_date == 0) ? (other.created_at <=> self.created_at) : compare_on_date
  end

  def is_overdue?
    self.due_status == OVERDUE
  end

  # The number of consecutive days upto the specified date; that the loan was overdue
  def self.unbroken_days_past_due(for_loan_id, on_date)
    generate_due_status_records_till_date(for_loan_id, on_date)
    days_past_due_till_date = all(:lending_id => for_loan_id, :on_date.lte => on_date).sort
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

  # The total number of days (not necessarily consecutive) that a loan was overdue upto the specified date
  def self.cumulative_days_past_due(for_loan_id, on_date)
    #TODO
  end

  # A list of the series of dates that the loan was overdue on consecutive days.
  # When the loan is overdue on two consecutive days, these days will belong to a range
  def self.days_past_due_episodes(for_loan_id, on_date)
    #TODO
  end

  def self.generate_loan_due_status(for_loan_id, on_date)
    loan = Lending.get(for_loan_id)
    loan_base_schedule = loan.loan_base_schedule
    loan_schedules = loan_base_schedule.base_schedule_line_items(:order => [:on_date, :created_at])
    zero_amount = MoneyManager.default_zero_money
    raise Errors::DataError, "Unable to locate the loan for ID: #{for_loan_id}" unless loan

    if Mfi.first.system_state == :migration
      location_map = LoanAdministration.first(:loan_id => for_loan_id)
    else
      location_map = LoanAdministration.get_location_map(for_loan_id, on_date)
      raise Errors::DataError, "Unable to determine loan locations" if location_map.blank?
    end

    unless location_map.blank?
      administered_at_id = location_map.administered_at
      accounted_at_id    = location_map.accounted_at

      due_status = {}
      due_status[:lending_id]      = for_loan_id
      due_status[:loan_status]     = loan.loan_status_on_date(on_date)
      due_status[:administered_at] = administered_at_id
      due_status[:accounted_at]    = accounted_at_id
      due_status[:on_date]         = on_date

    
      if loan.has_loan_claim?
        loan_claim_since = loan.has_loan_claim_since
        if (loan_claim_since and (on_date >= loan_claim_since))
          due_status[:has_loan_claim]       = true
          due_status[:has_loan_claim_since] = loan_claim_since
        end
      end

      schedules_info = loan_schedules.select{|s| s.on_date <= on_date}
      schedule_info = schedules_info.blank? ? [] : schedules_info.sort.last
      scheduled_principal_till_date = schedules_info.blank? ? zero_amount : MoneyManager.get_money_instance_least_terms(schedules_info.map(&:scheduled_principal_due).sum.to_i)
      scheduled_interest_till_date = schedules_info.blank? ? zero_amount : MoneyManager.get_money_instance_least_terms(schedules_info.map(&:scheduled_interest_due).sum.to_i)
      scheduled_total_due_till_date = scheduled_principal_till_date + scheduled_interest_till_date
      receipt_till_date_info = LoanReceipt.sum_till_date_for_loans(loan.id, on_date)
      receipt_on_date_info = LoanReceipt.sum_on_date_for_loans(loan.id, on_date)
      due_status_amounts = {}
      due_status_amounts[SCHEDULED_PRINCIPAL_OUTSTANDING] = schedule_info.blank? ? zero_amount : schedule_info.to_money[:scheduled_principal_outstanding]
      due_status_amounts[SCHEDULED_INTEREST_OUTSTANDING]  = schedule_info.blank? ? zero_amount : schedule_info.to_money[:scheduled_interest_outstanding]
      due_status_amounts[SCHEDULED_TOTAL_OUTSTANDING]     = due_status_amounts[SCHEDULED_PRINCIPAL_OUTSTANDING] + due_status_amounts[SCHEDULED_INTEREST_OUTSTANDING]
      due_status_amounts[SCHEDULED_PRINCIPAL_DUE]         = schedule_info.blank? ? zero_amount : schedule_info.to_money[:scheduled_principal_due]
      due_status_amounts[SCHEDULED_INTEREST_DUE]          = schedule_info.blank? ? zero_amount : schedule_info.to_money[:scheduled_interest_due]
      due_status_amounts[SCHEDULED_TOTAL_DUE]             = due_status_amounts[SCHEDULED_PRINCIPAL_DUE] + due_status_amounts[SCHEDULED_INTEREST_DUE]

      due_status_amounts[:principal_received_on_date]     = receipt_on_date_info.blank? ? zero_amount : receipt_on_date_info[:principal_received]
      due_status_amounts[:interest_received_on_date]      = receipt_on_date_info.blank? ? zero_amount : receipt_on_date_info[:interest_received]
      due_status_amounts[:principal_received_till_date]   = receipt_till_date_info.blank? ? zero_amount : receipt_till_date_info[:principal_received]
      due_status_amounts[:interest_received_till_date]    = receipt_till_date_info.blank? ? zero_amount : receipt_till_date_info[:interest_received]
      due_status_amounts[:advance_received_on_date]       = receipt_on_date_info.blank? ? zero_amount : receipt_on_date_info[:advance_received]
      due_status_amounts[:advance_adjusted_on_date]       = receipt_on_date_info.blank? ? zero_amount : receipt_on_date_info[:advance_adjusted]
      due_status_amounts[:advance_received_till_date]     = receipt_till_date_info.blank? ? zero_amount : receipt_till_date_info[:advance_received]
      due_status_amounts[:advance_adjusted_till_date]     = receipt_till_date_info.blank? ? zero_amount : receipt_till_date_info[:advance_adjusted]
      due_status_amounts[:advance_balance]                = due_status_amounts[:advance_received_till_date] - due_status_amounts[:advance_adjusted_till_date]
      actual_principal_outstanding                        = loan.to_money[:disbursed_amount] - due_status_amounts[:principal_received_till_date]
      total_received_till_date                            = due_status_amounts[:principal_received_till_date] + due_status_amounts[:interest_received_till_date]
      due_status_amounts[ACTUAL_PRINCIPAL_OUTSTANDING]    = actual_principal_outstanding
      due_status_amounts[ACTUAL_INTEREST_OUTSTANDING]     = loan_base_schedule.to_money[:total_interest_applicable] > due_status_amounts[:interest_received_till_date] ? loan_base_schedule.to_money[:total_interest_applicable] - due_status_amounts[:interest_received_till_date] : zero_amount
      due_status_amounts[ACTUAL_TOTAL_OUTSTANDING]        = due_status_amounts[ACTUAL_PRINCIPAL_OUTSTANDING] + due_status_amounts[ACTUAL_INTEREST_OUTSTANDING]
      due_status_amounts[ACTUAL_TOTAL_DUE]                = scheduled_total_due_till_date > total_received_till_date ? scheduled_total_due_till_date - total_received_till_date : zero_amount
    
      if due_status[:loan_status] == DISBURSED_LOAN_STATUS
        if loan.scheduled_first_repayment_date > on_date
          loan_due_status = NOT_DUE
        elsif due_status_amounts[ACTUAL_TOTAL_DUE] > zero_amount
          loan_due_status = OVERDUE
        else
          loan_due_status = DUE
        end
      else
        loan_due_status = NOT_APPLICABLE
      end
      due_status[:due_status] = loan_due_status
      last_due_status = first(:lending_id => for_loan_id, :on_date => (on_date - 1), :order => [:on_date.desc, :created_at.desc])
      last_over_due = last_due_status.blank? ? 0 : last_due_status.day_past_due
      today_day_past_due = last_due_status.blank? || on_date == last_due_status.on_date ? overdue_day_on_date(for_loan_id, on_date) : last_over_due+1
      due_status[:day_past_due] = due_status[:due_status] == OVERDUE ? today_day_past_due : 0
      due_status_amounts[PRINCIPAL_AT_RISK] = (loan_due_status == OVERDUE) ? (actual_principal_outstanding) : zero_amount

      due_status.merge!(Money.from_money(due_status_amounts))
      if !schedule_info.blank?
        if schedule_info.on_date == on_date || loan_schedules.last.on_date <= on_date
          due_status[:interest_accrual_till_date] = scheduled_interest_till_date.amount
        else
          next_schedule = loan_schedules.select{|s| s.on_date >= on_date}.first
          next_schedule_interest = scheduled_interest_till_date + next_schedule.to_money[:scheduled_interest_due]
          due_status[:interest_accrual_till_date] = (scheduled_interest_till_date + Allocation::Common.calculate_broken_period_interest(scheduled_interest_till_date, next_schedule_interest, schedule_info.on_date, next_schedule.on_date, on_date, loan.repayment_frequency)).amount

        end
      else
        due_status[:interest_accrual_till_date] = zero_amount.amount
      end
      loan_due_status_record  = first_or_create(due_status)
      raise Errors::DataError, loan_due_status_record.errors.first.first unless loan_due_status_record.saved?
      loan_due_status_record
    end
  end

  # If a record exists on any date, get the most recent record on the date
  # If a record does not exist on any date, generate a record, then return the most recent record on the date
  def self.most_recent_status_record_on_date(for_loan_id, on_date)
    most_recent_status = first(:lending_id => for_loan_id, :on_date => on_date, :order => [:on_date.desc, :created_at.desc])
    most_recent_status || generate_loan_due_status(for_loan_id, on_date)
  end

  def self.generate_due_status_records_till_date(for_loan_id, on_date)
    loan = Lending.get(for_loan_id)
    raise Errors::DataError, "Unable to locate the loan for ID: #{for_loan_id}" unless loan

    scheduled_first_repayment_date = loan.scheduled_first_repayment_date
    return unless (loan.disbursal_date and (on_date >= scheduled_first_repayment_date))

    status_dates = all(:lending_id => for_loan_id, :on_date => (scheduled_first_repayment_date..on_date)).aggregate(:on_date).uniq
    remaining_dates = (scheduled_first_repayment_date..on_date).to_a - status_dates

    remaining_dates.each { |each_date|
      most_recent_status_record_on_date(for_loan_id, each_date)
    }
  end

  def self.most_recent_status_record
    first(:order => [:on_date.desc, :created_at.desc])
  end

  def money_amounts
    [
      SCHEDULED_PRINCIPAL_OUTSTANDING,
      SCHEDULED_INTEREST_OUTSTANDING,
      SCHEDULED_TOTAL_OUTSTANDING,
      SCHEDULED_PRINCIPAL_DUE,
      SCHEDULED_INTEREST_DUE,
      SCHEDULED_TOTAL_DUE,
      ACTUAL_PRINCIPAL_OUTSTANDING,
      PRINCIPAL_AT_RISK,
      ACTUAL_INTEREST_OUTSTANDING,
      ACTUAL_TOTAL_OUTSTANDING,
      ACTUAL_TOTAL_DUE,
      :principal_received_on_date,
      :interest_received_on_date,
      :principal_received_till_date,
      :interest_received_till_date,
      :advance_received_on_date,
      :advance_adjusted_on_date,
      :advance_received_till_date,
      :advance_adjusted_till_date,
      :advance_balance
    ]
  end

  def self.overdue_day_on_date(loan_id, on_date)
    overdue_days = 0
    loan = Lending.get loan_id
    first_repayment_date = loan.scheduled_first_repayment_date
    max_overdue_days = on_date > first_repayment_date ? (on_date-first_repayment_date).to_i : 0
    schedules = loan.loan_base_schedule.base_schedule_line_items(:on_date.lte => on_date, :installment.not => 0)
    schedule_dates = schedules.blank? ? [] : schedules.map(&:on_date)

    loan_receipts = loan.loan_receipts(:effective_on.lte => on_date)
    loan_receipts_date = loan_receipts.blank? ? [] : loan_receipts.map(&:effective_on)
    total_received = loan_receipts.blank? ? 0 :loan_receipts.map(&:principal_received).sum.to_i + loan_receipts.map(&:interest_received).sum.to_i
    if loan.is_outstanding_on_date?(on_date)
      if loan_receipts.blank?
        overdue_days = max_overdue_days
      else
        dates = schedule_dates.include?(on_date) ? schedule_dates+loan_receipts_date : (schedule_dates+loan_receipts_date)<<on_date
        dates.sort.reverse.each do |r_date|
          schedule_till_date = schedule_dates.include?(r_date) ? schedules.select{|s| s.on_date < r_date} : schedules.select{|s| s.on_date <= r_date}
          if !schedule_till_date.blank? && !loan_receipts.blank?
            total_schedule_due = schedule_till_date.map(&:scheduled_principal_due).sum.to_i + schedule_till_date.map(&:scheduled_interest_due).sum.to_i
            if total_schedule_due > total_received
              overdue_days = max_overdue_days
            else
              overdue_days = max_overdue_days - (r_date-first_repayment_date).to_i
              break
            end
          end
        end
      end
    else
      overdue_days = 0
    end
    overdue_days
  end

end
