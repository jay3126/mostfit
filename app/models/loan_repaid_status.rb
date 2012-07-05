class LoanRepaidStatus
  include DataMapper::Resource
  include LoanLifeCycle, Constants::Properties

  property :id,                            Serial
  property :repaid_nature,                 Enum.send('[]', *REPAID_NATURES), :nullable => false
  property :repaid_on_date,                *DATE_NOT_NULL
  property :closing_outstanding_principal, *MONEY_AMOUNT
  property :closing_outstanding_interest,  *MONEY_AMOUNT
  property :closing_outstanding_total,     *MONEY_AMOUNT
  property :currency,                      *CURRENCY
  property :created_at,                    *CREATED_AT

  belongs_to :lending

  def money_amounts; [:closing_outstanding_principal, :closing_outstanding_interest, :closing_outstanding_total]; end

  def closing_outstanding_principal_money_amount; to_money_amount(:closing_outstanding_principal); end
  def closing_outstanding_interest_money_amount; to_money_amount(:closing_outstanding_interest); end
  def closing_outstanding_total_money_amount; to_money_amount(:closing_outstanding_total); end

  def self.to_loan_repaid_status(for_loan, repaid_nature, repaid_on_date, closing_oustanding_principal_money_amount, closing_outstanding_interest_money_amount)
    Validators::Arguments.not_nil?(for_loan, repaid_nature, repaid_on_date, closing_oustanding_principal_money_amount, closing_outstanding_interest_money_amount)
    loan_repaid_status = {}
    loan_repaid_status[:lending] = for_loan
    loan_repaid_status[:repaid_nature] = repaid_nature
    loan_repaid_status[:repaid_on_date] = repaid_on_date
    loan_repaid_status[:closing_outstanding_principal] = closing_oustanding_principal_money_amount.amount
    loan_repaid_status[:closing_outstanding_interest] = closing_outstanding_interest_money_amount.amount
    loan_repaid_status[:closing_outstanding_total] = (closing_oustanding_principal_money_amount + closing_outstanding_interest_money_amount).amount
    loan_repaid_status[:currency] = closing_oustanding_principal_money_amount.currency
    new(loan_repaid_status)
  end

end
