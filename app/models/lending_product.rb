class LendingProduct
  include DataMapper::Resource
  include Constants::Properties, Constants::Money, Constants::Loan, Constants::LoanAmounts, Constants::Transaction, MarkerInterfaces::Recurrence
  
  property :id,                             Serial
  property :name,                           *NAME
  property :amount,                         *MONEY_AMOUNT
  property :currency,                       *CURRENCY
  property :interest_rate,                  *FLOAT_NOT_NULL
  property :repayment_frequency,            *FREQUENCY
  property :tenure,                         *TENURE
  property :repayment_allocation_strategy,  Enum.send('[]', *LOAN_REPAYMENT_ALLOCATION_STRATEGIES), :nullable => false
  property :created_at,                     *CREATED_AT

  def money_amounts; [:amount]; end

  def loan_money_amount; to_money_amount(:amount); end

  has 1, :loan_schedule_template
  has n, :lendings
  has 1, :loan_fee, 'SimpleFeeProduct'
  has n, :simple_insurance_products

  # Implementing MarkerInterfaces::Recurrence#frequency
  def frequency; self.repayment_frequency; end

  def amortization; self.loan_schedule_template.amortization; end

  # Create a loan product, and the corresponding loan schedule template
  def self.create_lending_product(
    name,
    standard_loan_money_amount,
    total_interest_applicable_money_amount,
    annual_interest_rate,
    repayment_frequency,
    tenure,
    repayment_allocation_strategy,
    principal_amounts,
    interest_amounts
  )
    Validators::Amortization.is_valid_amortization?(tenure, standard_loan_money_amount, total_interest_applicable_money_amount, principal_amounts, interest_amounts)

    product = {}
    product[:name] = name
    product[:amount] = standard_loan_money_amount.amount
    product[:currency] = standard_loan_money_amount.currency
    product[:interest_rate] = annual_interest_rate
    product[:repayment_frequency] = repayment_frequency
    product[:tenure] = tenure
    product[:repayment_allocation_strategy] = repayment_allocation_strategy
    new_product = first_or_create(product)
    raise Errors::DataError, new_product.errors.first.first unless new_product.saved?

    principal_and_interest_amounts = assemble_amortization(tenure, principal_amounts, interest_amounts)
    LoanScheduleTemplate.create_schedule_template(name, standard_loan_money_amount, total_interest_applicable_money_amount, tenure, repayment_frequency, new_product, principal_and_interest_amounts)
    new_product
  end

  # Creates a data structure that has both the principal and interest amounts to be repaid on each installment
  def self.assemble_amortization(tenure, principal_amounts, interest_amounts)
    amortization = {}
    1.upto(tenure).each { |installment|
      amortization[installment] = {
          PRINCIPAL_AMOUNT => principal_amounts[installment - 1],
          INTEREST_AMOUNT  => interest_amounts[installment - 1]
      }
    }
    amortization
  end

  def total_interest_money_amount
    self.loan_schedule_template.total_interest_money_amount
  end

end
