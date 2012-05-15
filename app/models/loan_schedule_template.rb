class LoanScheduleTemplate
  include DataMapper::Resource
  include Constants::Properties, Constants::Money, MarkerInterfaces::Recurrence

  # Loan schedule template does not have dates on the schedule line items

  belongs_to :lending_product
  has n, :schedule_template_line_items

  property :id,                     Serial
  property :name,                   *NAME
  property :total_principal_amount, *MONEY_AMOUNT
  property :total_interest_amount,  *MONEY_AMOUNT
  property :currency,               *CURRENCY
  property :num_of_installments,    *TENURE
  property :repayment_frequency,    *FREQUENCY
  property :created_at,             *CREATED_AT

  def money_amounts; [:total_principal_amount, :total_interest_amount]; end

  # Implements MarkerInterfaces::Recurrence#frequency
  def frequency; self.repayment_frequency; end

  def self.create_schedule_template(name, total_principal_money_amount, total_interest_money_amount, num_of_installments, repayment_frequency, lending_product, principal_and_interest_amounts)
    schedule_template = to_schedule_template(name, total_principal_money_amount, total_interest_money_amount, num_of_installments, repayment_frequency, lending_product)
    ScheduleTemplateLineItem.create_schedule_line_items(schedule_template, principal_and_interest_amounts)
  end

  def get_amortization
    #TBD
  end

  private

  def self.to_schedule_template(name, total_principal_money_amount, total_interest_money_amount, num_of_installments, repayment_frequency, lending_product)
    Validators::Arguments.not_nil?(name, total_principal_money_amount, total_interest_money_amount, num_of_installments, repayment_frequency)
    schedule_template = {}
    schedule_template[:name] = name
    schedule_template[:total_principal_amount] = total_principal_money_amount.amount
    schedule_template[:total_interest_amount] = total_interest_money_amount.amount
    schedule_template[:currency] = total_principal_money_amount.currency
    schedule_template[:num_of_installments] = num_of_installments
    schedule_template[:repayment_frequency] = repayment_frequency
    schedule_template[:lending_product] = lending_product
    new(schedule_template)
  end

end

class ScheduleTemplateLineItem
  include DataMapper::Resource
  include Comparable
  include Constants::Properties, Constants::Money, Constants::Loan, Constants::Transaction
  include Validators::Amounts

  belongs_to :loan_schedule_template

  property :id,               Serial
  property :installment,      Integer, :nullable => false, :min => 0
  property :payment_type,     Enum.send('[]', *LOAN_PAYMENT_TYPES), :nullable => false
  property :principal_amount, *MONEY_AMOUNT
  property :interest_amount,  *MONEY_AMOUNT
  property :currency,         *CURRENCY
  property :created_at,       *CREATED_AT

  def money_amounts; [:principal_amount, :interest_amount]; end

  # Sorts in the ascending order of installment
  def <=>(other)
    other.is_a?(ScheduleTemplateLineItem) ? self.installment <=> other.installment : nil
  end

  def self.create_schedule_line_items(schedule_template, principal_and_interest_amounts)
    schedule_line_items = []

    total_principal_amount = schedule_template.total_principal_amount
    currency = schedule_template.currency

    disbursement = to_line_item(0, DISBURSEMENT, total_principal_amount, 0, currency)
    schedule_line_items << disbursement

    installments = principal_and_interest_amounts.keys

    installments.each { |num|
      next unless num > 0
      principal_and_interest = principal_and_interest_amounts[num]
      principal_amount = principal_and_interest[PRINCIPAL_AMOUNT].amount
      interest_amount = principal_and_interest[INTEREST_AMOUNT].amount
      repayment = to_line_item(num, REPAYMENT, principal_amount, interest_amount, currency)
      schedule_line_items << repayment
    }

    schedule_template.schedule_template_line_items = schedule_line_items.sort
    schedule_template.save
    raise Errors::DataError, schedule_template.errors.first.first unless schedule_template.saved?
    schedule_template
  end

  def self.to_line_item(installment, payment_type, principal_amount, interest_amount, currency)
    line_item = {}
    line_item[:installment] = installment
    line_item[:payment_type] = payment_type
    line_item[:principal_amount] = principal_amount
    line_item[:interest_amount] = interest_amount
    line_item[:currency] = currency
    new(line_item)
  end

end
