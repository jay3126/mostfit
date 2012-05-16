class LoanBaseSchedule
  include DataMapper::Resource
  include Constants::Money, Constants::Loan, MarkerInterfaces::Recurrence, Constants::Transaction, Constants::Properties

  # The loan base schedule is created once and is immutable
  # (unless re-scheduled, which is not currently supported)
  # The loan base schedule has dates on it

  belongs_to :lending
  has n, :base_schedule_line_items

  property :id,                     Serial
  property :total_principal_amount, *MONEY_AMOUNT
  property :total_interest_amount,  *MONEY_AMOUNT
  property :currency,               *CURRENCY
  property :first_disbursed_on,     *DATE_NOT_NULL
  property :first_receipt_on,       *DATE_NOT_NULL
  property :repayment_frequency,    *FREQUENCY
  property :tenure,                 *TENURE
  property :num_of_installments,    *TENURE
  property :created_at,             *CREATED_AT

  def money_amounts; [:total_principal_amount, :total_interest_amount]; end

  # Implementing MarkerInterfaces::Recurrence#frequency
  def frequency; self.repayment_frequency; end

  # Get the base schedule balances on the specified date
  # If the date specified is before the disbursement date, this returns the schedule balances on disbursement date
  # if the date specified is on or after the last scheduled repayment date, this returns the schedule balances on
  # the last scheduled repayment date
  # In general, this returns the schedule balances on the date or the next date immediately following it
  # However, by specifying true for the last argument, it can return the balances from the previous date immediately
  # preceding the specified date
  # @param [Date] on_date (defaults to Date.today)
  # @param [TrueClass] get_earlier_date (defaults to false)
  def get_schedule_balances(on_date = Date.today, get_earlier_date = false)
    return get_schedule_line_item(self.first_disbursed_on) if on_date <= self.first_disbursed_on

    all_schedule_dates = get_schedule_dates

    last_schedule_date = all_schedule_dates.last
    return get_schedule_line_item(last_schedule_date) if on_date >= last_schedule_date

    schedule_date = get_earlier_date ? Constants::Time.get_immediately_earlier_date(on_date, *all_schedule_dates) :
        Constants::Time.get_immediately_next_date(on_date, *all_schedule_dates)

    schedule_date ? get_schedule_line_item(schedule_date) : nil
  end

  def self.create_base_schedule(total_principal_money_amount, total_interest_money_amount, first_disbursed_on, first_receipt_on, repayment_frequency, tenure, num_of_installments, lending, principal_and_interest_amounts)
    base_schedule = to_base_schedule(total_principal_money_amount, total_interest_money_amount, first_disbursed_on, first_receipt_on, repayment_frequency, tenure, num_of_installments, lending)
    BaseScheduleLineItem.create_schedule_line_items(base_schedule, principal_and_interest_amounts)
  end

  # Fetches a list of schedule dates ordered chronologically
  def get_schedule_dates
    self.base_schedule_line_items.sort.collect {|line_item| line_item.on_date}
  end

  private

  # Only fetches the schedule line item for the specified date,
  #if there is a schedule line item
  # @param [Date] on_date
  def get_schedule_line_item(on_date)
    self.base_schedule_line_items.first(:on_date => on_date)
  end

  def self.to_base_schedule(total_principal_money_amount, total_interest_money_amount, first_disbursed_on, first_receipt_on, repayment_frequency, tenure, num_of_installments, lending)
    Validators::Arguments.not_nil?(total_principal_money_amount, total_interest_money_amount, first_disbursed_on, first_receipt_on, repayment_frequency, tenure, lending,num_of_installments)
    base_schedule = {}
    base_schedule[:total_principal_amount] = total_principal_money_amount.amount
    base_schedule[:total_interest_amount] = total_interest_money_amount.amount
    base_schedule[:currency] = total_principal_money_amount.currency
    base_schedule[:first_disbursed_on] = first_disbursed_on
    base_schedule[:first_receipt_on] = first_receipt_on
    base_schedule[:repayment_frequency] = repayment_frequency
    base_schedule[:tenure] = tenure
    base_schedule[:num_of_installments] = num_of_installments
    base_schedule[:lending] = lending
    new(base_schedule)
  end

end

class BaseScheduleLineItem
  include DataMapper::Resource
  include Constants::Properties, Constants::Money, Constants::Loan, Validators::Amounts, Constants::Transaction
  include Comparable

  belongs_to :loan_base_schedule

  property :id,                       Serial
  property :installment,              *INSTALLMENT
  property :on_date,                  *DATE_NOT_NULL
  property :payment_type,             Enum.send('[]', *LOAN_PAYMENT_TYPES), :nullable => false
  property :principal_balance_before, *MONEY_AMOUNT
  property :principal_amount_due,     *MONEY_AMOUNT
  property :principal_balance_after,  *MONEY_AMOUNT
  property :interest_balance_before,  *MONEY_AMOUNT
  property :interest_amount_due,      *MONEY_AMOUNT
  property :interest_balance_after,   *MONEY_AMOUNT
  property :currency,                 *CURRENCY
  property :created_at,               *CREATED_AT

  def money_amounts
    [ :principal_balance_before, :principal_amount_due, :principal_balance_after,
      :interest_balance_before, :interest_amount_due, :interest_balance_after ]
  end

  # Order chronologically by on_date
  def <=>(other)
    other.respond_to?(:on_date) ? self.on_date <=> other.on_date : nil
  end

  # Given a loan base schedule, create the loan schedule line items
  def self.create_schedule_line_items(base_schedule, principal_and_interest_amounts)
    schedule_line_items = []

    total_principal_amount = base_schedule.total_principal_amount
    total_interest_amount = base_schedule.total_interest_amount
    currency = base_schedule.currency
    first_disbursed_on = base_schedule.first_disbursed_on
    repayment_frequency = base_schedule.frequency

    disbursement = get_instance(0, first_disbursed_on, DISBURSEMENT, 0, 0, 0, 0, currency, total_principal_amount, total_interest_amount)
    schedule_line_items << disbursement

    repayment_on = base_schedule.first_receipt_on
    principal_balance_before = total_principal_amount; interest_balance_before = total_interest_amount
    installments = principal_and_interest_amounts.keys

    installments.each { |num|
      next unless num > 0
      principal_and_interest = principal_and_interest_amounts[num]
      principal_amount_due = principal_and_interest[PRINCIPAL_AMOUNT].amount
      interest_amount_due = principal_and_interest[INTEREST_AMOUNT].amount

      repayment_on = Constants::Time.get_next_date(repayment_on, repayment_frequency)

      repayment = get_instance(num, repayment_on, REPAYMENT, principal_balance_before, principal_amount_due, interest_balance_before, interest_amount_due, currency)
      schedule_line_items << repayment

      principal_balance_before -= principal_amount_due
      interest_balance_before -= interest_amount_due
    }

    base_schedule.base_schedule_line_items = schedule_line_items
    was_saved = base_schedule.save
    raise Errors::DataError, base_schedule.errors.first.first unless was_saved
    base_schedule
  end

  # Constructs an instance of this class
  def self.get_instance(installment, on_date, payment_type, principal_balance_before, principal_amount_due, interest_balance_before, interest_amount_due, currency, principal_balance_after = nil, interest_balance_after = nil)
    Validators::Amounts.is_positive?(principal_balance_before, principal_amount_due, interest_balance_before, interest_amount_due)
    Validators::Amounts.is_positive?(principal_balance_after, interest_balance_after) if payment_type == DISBURSEMENT
    line_item = {}
    line_item[:installment] = installment
    line_item[:on_date] = on_date
    line_item[:payment_type] = payment_type

    if (payment_type == DISBURSEMENT)
      line_item[:principal_balance_before] = 0
      line_item[:principal_amount_due] = 0
      line_item[:principal_balance_after] = principal_balance_after
      line_item[:interest_balance_before] = 0
      line_item[:interest_amount_due] = 0
      line_item[:interest_balance_after] = interest_balance_after
    else
      line_item[:principal_balance_before] = principal_balance_before
      line_item[:principal_amount_due] = principal_amount_due
      line_item[:principal_balance_after] = principal_balance_before - principal_amount_due
      line_item[:interest_balance_before] = interest_balance_before
      line_item[:interest_amount_due] = interest_amount_due
      line_item[:interest_balance_after] = interest_balance_before - interest_amount_due
    end

    line_item[:currency] = currency
    new(line_item)
  end

end
