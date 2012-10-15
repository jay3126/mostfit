class LoanBaseSchedule
  include DataMapper::Resource
  include Constants::Money, Constants::Loan, Constants::LoanAmounts, Constants::Transaction, Constants::Properties
  include MarkerInterfaces::Recurrence

  # The loan base schedule is created once and is immutable
  # (unless re-scheduled, which is not currently supported)
  # The loan base schedule has dates on it

  belongs_to :lending
  has n, :base_schedule_line_items

  property :id,                       Serial
  property TOTAL_LOAN_DISBURSED,      *MONEY_AMOUNT
  property TOTAL_INTEREST_APPLICABLE, *MONEY_AMOUNT
  property :currency,                 *CURRENCY
  property :first_disbursed_on,       *DATE_NOT_NULL
  property :first_receipt_on,         *DATE_NOT_NULL
  property :repayment_frequency,      *FREQUENCY
  property :num_of_installments,      *TENURE
  property :created_at,               *CREATED_AT

  def money_amounts
    [TOTAL_LOAN_DISBURSED, TOTAL_INTEREST_APPLICABLE]
  end

  ##########################
  # LOAN SCHEDULE PROPERTIES # begins
  ##########################

  def total_loan_disbursed_money_amount
    to_money_amount(TOTAL_LOAN_DISBURSED)
  end

  def total_interest_applicable_money_amount
    to_money_amount(TOTAL_INTEREST_APPLICABLE)
  end

  # Implementing MarkerInterfaces::Recurrence#frequency
  def frequency
    self.repayment_frequency
  end

  ##########################
  # LOAN SCHEDULE PROPERTIES # ends
  ##########################

  #######################
  # LOAN SCHEDULE DATES # begins
  #######################

  # Fetches a list of schedule dates ordered chronologically
  def get_schedule_dates
    self.base_schedule_line_items.sort.collect { |line_item| line_item.on_date }
  end

  def get_schedule_date_range
    get_schedule_dates.first..get_schedule_dates.last
  end

  # Tests whether the specified date is a schedule date on the amortization
  def is_schedule_date?(on_date)
    get_schedule_dates.include?(on_date)
  end

  # Gets the immediately previous and current schedule dates
  def get_previous_and_current_schedule_dates(on_date = Date.today)
    return on_date if is_schedule_date?(on_date)

    return [nil, self.first_disbursed_on] if on_date <= self.first_disbursed_on

    all_schedule_dates = get_schedule_dates
    last_schedule_date = get_schedule_dates.sort.last
    return [last_schedule_date, nil] if on_date > last_schedule_date

    return [Constants::Time.get_immediately_earlier_date(on_date, *all_schedule_dates),
      Constants::Time.get_immediately_next_date(on_date, *all_schedule_dates)]
  end

  #######################
  # LOAN SCHEDULE DATES # ends
  #######################

  ###########################
  # LOAN AMORTIZATION queries # begins
  ###########################

  # Get the previous and current amortization items on the specified date
  # If the date specified is on or before the disbursement date, this returns [nil, amortization on disbursement date]
  # If the date specified is after the last scheduled repayment date, this returns [amortization on last scheduled repayment date, nil]
  # If the date specified is a schedule date, this returns [amortization on previous scheduled repayment date, amortization on the date]
  # If the date specified falls between schedule dates, this returns [amortization on previous scheduled repayment date, amortization on next scheduled repayment date]
  # @param [Date] on_date (defaults to Date.today)
  def get_previous_and_current_amortization_items(on_date = Date.today)
    nearest_schedule_dates_val = get_previous_and_current_schedule_dates(on_date)

    if nearest_schedule_dates_val.is_a?(Array)
      return nearest_schedule_dates_val.collect { |date_val| date_val.nil? ? nil : get_amortization(date_val)}
    else
      return get_amortization(nearest_schedule_dates_val)
    end
  end

  def get_all_amortization_items_till_date(date = Date.today)
    later_date = get_previous_and_current_schedule_dates(date)
    later_date = later_date.compact.max if later_date.is_a?(Array)
    get_all_previous_amortization(later_date)
  end

  def get_schedule_after_date(on_date)
    self.base_schedule_line_items.all(:on_date.gte => on_date)
  end

  ###########################
  # LOAN AMORTIZATION queries # ends
  ###########################

  def self.create_base_schedule(total_loan_disbursed, total_interest_applicable, first_disbursed_on, first_receipt_on, repayment_frequency, num_of_installments, lending, amortization)
    base_schedule = to_base_schedule(total_loan_disbursed, total_interest_applicable, first_disbursed_on, first_receipt_on, repayment_frequency, num_of_installments, lending)
    BaseScheduleLineItem.create_schedule_line_items(base_schedule, amortization)
  end

  private

  # Fetches the amortization on date
  def get_amortization(on_date)
    schedule_line_item = get_schedule_line_item(on_date)
    schedule_line_item ? schedule_line_item.to_amortization : nil
  end

  def get_all_previous_amortization(on_or_before_date)
    get_schedule_line_items_until(on_or_before_date).collect {|line_item| line_item.to_amortization}
  end

  # Only fetches the schedule line item for the specified date,
  #if there is a schedule line item
  # @param [Date] on_date
  def get_schedule_line_item(on_date)
    self.base_schedule_line_items.first(:on_date => on_date)
  end

  def get_schedule_line_items_until(date)
    self.base_schedule_line_items.all(:on_date.lte => date)
  end

  def self.to_base_schedule(total_loan_disbursed, total_interest_applicable, first_disbursed_on, first_receipt_on, repayment_frequency, num_of_installments, lending)
    Validators::Arguments.not_nil?(total_loan_disbursed, total_interest_applicable, first_disbursed_on, first_receipt_on, repayment_frequency, lending, num_of_installments)
    base_schedule                            = { }
    base_schedule[TOTAL_LOAN_DISBURSED]      = total_loan_disbursed.amount
    base_schedule[TOTAL_INTEREST_APPLICABLE] = total_interest_applicable.amount
    base_schedule[:currency]                 = total_loan_disbursed.currency
    base_schedule[:first_disbursed_on]       = first_disbursed_on
    base_schedule[:first_receipt_on]         = first_receipt_on
    base_schedule[:repayment_frequency]      = repayment_frequency
    base_schedule[:num_of_installments]      = num_of_installments
    base_schedule[:lending]                  = lending
    new(base_schedule)
  end

end

class BaseScheduleLineItem
  include DataMapper::Resource
  include Constants::Properties, Constants::Money, Constants::Loan, Constants::LoanAmounts, Constants::Transaction
  include Validators::Amounts
  include Comparable

  belongs_to :loan_base_schedule

  property :id,                             Serial
  property :installment,                    *INSTALLMENT
  property :on_date,                        *DATE_NOT_NULL
  property :actual_date,                    *DATE
  property :payment_type,                   Enum.send('[]', *LOAN_PAYMENT_TYPES), :nullable => false
  property SCHEDULED_PRINCIPAL_OUTSTANDING, *MONEY_AMOUNT
  property SCHEDULED_PRINCIPAL_DUE,         *MONEY_AMOUNT
  property SCHEDULED_INTEREST_OUTSTANDING,  *MONEY_AMOUNT
  property SCHEDULED_INTEREST_DUE,          *MONEY_AMOUNT
  property :currency,                       *CURRENCY
  property :updated_at,                     *UPDATED_AT
  property :created_at,                     *CREATED_AT

  before :save, :date_change_according_to_holiday

  # Returns a data structure as follows:
  # Hash with
  # Array as key: [installment, date]
  # Values: { :scheduled_principal_outstanding => money_amount, etc. }
  def to_amortization
    {[installment, on_date] => to_money}
  end

  def money_amounts
    [ SCHEDULED_PRINCIPAL_OUTSTANDING, SCHEDULED_PRINCIPAL_DUE,
      SCHEDULED_INTEREST_OUTSTANDING, SCHEDULED_INTEREST_DUE ]
  end

  # Order chronologically by on_date
  def <=>(other)
    other.respond_to?(:on_date) ? self.on_date <=> other.on_date : nil
  end

  # Given a loan base schedule, create the loan schedule line items
  def self.create_schedule_line_items(base_schedule, amortization)
    schedule_line_items = []

    total_loan_disbursed      = base_schedule.total_loan_disbursed
    total_interest_applicable = base_schedule.total_interest_applicable
    currency                  = base_schedule.currency
    first_disbursed_on        = base_schedule.first_disbursed_on
    repayment_frequency       = base_schedule.frequency

    disbursement = get_instance(0, first_disbursed_on, DISBURSEMENT, total_loan_disbursed, 0, total_interest_applicable, 0, currency)
    schedule_line_items << disbursement

    repayment_on                    = base_schedule.first_receipt_on
    scheduled_principal_outstanding = total_loan_disbursed
    scheduled_interest_outstanding  = total_interest_applicable
    installments                    = amortization.keys.sort

    installments.each { |num|
      next unless num > 0
      principal_and_interest_installment = amortization[num]
      scheduled_principal_due            = principal_and_interest_installment[PRINCIPAL_AMOUNT].amount
      scheduled_interest_due             = principal_and_interest_installment[INTEREST_AMOUNT].amount
      repayment_on = Constants::Time.get_next_date(repayment_on, repayment_frequency) if (num > 1)

      scheduled_principal_outstanding -= scheduled_principal_due
      raise Errors::BusinessValidationError, "Scheduled principal due: #{scheduled_principal_due} exceeds scheduled principal outstanding: #{scheduled_principal_outstanding}" if scheduled_principal_outstanding < 0

      scheduled_interest_outstanding  -= scheduled_interest_due
      raise Errors::BusinessValidationError, "Scheduled interest due: #{scheduled_interest_due} exceeds scheduled interest outstanding #{scheduled_interest_outstanding}" if scheduled_interest_outstanding < 0

      repayment = get_instance(num, repayment_on, REPAYMENT, scheduled_principal_outstanding, scheduled_principal_due, scheduled_interest_outstanding, scheduled_interest_due, currency)
      schedule_line_items << repayment
    }

    base_schedule.base_schedule_line_items = schedule_line_items.sort
    was_saved                              = base_schedule.save
    raise Errors::DataError, base_schedule.errors.first.first unless was_saved
    base_schedule
  end

  # Constructs an instance of this class
  def self.get_instance(installment, on_date, payment_type, scheduled_principal_outstanding, scheduled_principal_due, scheduled_interest_outstanding, scheduled_interest_due, currency)
    Validators::Amounts.is_positive?(scheduled_principal_outstanding, scheduled_principal_due, scheduled_interest_outstanding, scheduled_interest_due)
    line_item                                  = { }
    line_item[:installment]                    = installment
    line_item[:on_date]                        = on_date
    line_item[:actual_date]                    = on_date
    line_item[:payment_type]                   = payment_type
    line_item[SCHEDULED_PRINCIPAL_OUTSTANDING] = scheduled_principal_outstanding
    line_item[SCHEDULED_PRINCIPAL_DUE]         = scheduled_principal_due
    line_item[SCHEDULED_INTEREST_OUTSTANDING]  = scheduled_interest_outstanding
    line_item[SCHEDULED_INTEREST_DUE]          = scheduled_interest_due
    line_item[:currency]                       = currency
    new(line_item)
  end

  def date_change_according_to_holiday
    location = self.loan_base_schedule.lending.administered_at_origin_location
    holiday = LocationHoliday.get_any_holiday(location, self.on_date)
    self.on_date = holiday.move_work_to_date unless holiday.blank?
  end

end

class Amortization < Hash
  include Constants::LoanAmounts
end
