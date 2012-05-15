class Lending
  include DataMapper::Resource
  include Constants::Money, Constants::Loan, Constants::Properties, MarkerInterfaces::Recurrence
  include Validators::Arguments

  property :id, Serial
  property :lan,                            *UNIQUE_ID
  property :applied_amount,                 *MONEY_AMOUNT
  property :currency,                       *CURRENCY
  property :for_borrower_id,                *INTEGER_NOT_NULL
  property :applied_on_date,                *DATE_NOT_NULL
  property :approved_amount,                *MONEY_AMOUNT_NULL
  property :scheduled_disbursal_date,       *DATE_NOT_NULL
  property :scheduled_first_repayment_date, *DATE_NOT_NULL
  property :repayment_frequency,            *FREQUENCY
  property :tenure,                         *TENURE
  property :administered_at_origin,         *INTEGER_NOT_NULL
  property :accounted_at_origin,            *INTEGER_NOT_NULL
  property :applied_by_staff,               *INTEGER_NOT_NULL
  property :recorded_by_user,               *INTEGER_NOT_NULL
  property :status,                         Enum.send('[]', *LOAN_STATUSES), :nullable => false, :default => NEW
  property :created_at,                     *CREATED_AT
  property :updated_at,                     *UPDATED_AT
  property :deleted_at,                     *DELETED_AT

  def money_amounts; [:applied_amount, :approved_amount]; end

  belongs_to :lending_product
  has 1, :loan_base_schedule
  has n, :loan_allocations
  has n, :loan_due_statuses

  def self.create_new_loan(for_amount, repayment_frequency, tenure, from_lending_product, for_borrower_id,
      administered_at_origin, accounted_at_origin, applied_on_date, scheduled_disbursal_date, scheduled_first_repayment_date,
      applied_by_staff, recorded_by_user, lan = nil)
    new_loan = to_loan(for_amount, repayment_frequency, tenure, from_lending_product, for_borrower_id,
                       administered_at_origin, accounted_at_origin, applied_on_date, scheduled_disbursal_date, scheduled_first_repayment_date,
                       applied_by_staff, recorded_by_user, lan)
    was_saved = new_loan.save
    raise Errors::DataError, new_loan.errors.first.first unless was_saved
    new_loan
  end

  def self.create_approved_loan(for_amount, repayment_frequency, tenure, from_lending_product, for_client,
      administered_at_origin, accounted_at_origin, applied_on_date, scheduled_disbursal_date, scheduled_first_repayment_date,
      applied_by_staff, approved_amount, approved_on_date, approved_by_staff, recorded_by_user, lan = nil)
    #TBD
  end

  def approve
  end

  def reject
  end

  def disburse
  end

  def cancel
  end

  def repay
  end

  def pre_close
  end

  # Total principal repaid till date
  def total_principal_repaid(on_or_before_date = nil)
    #TBD
  end

  # Total interest received till date
  def total_interest_received(on_or_before_date = nil)
    #TBD
  end

  # Obtain the current loan status
  def get_current_status;
    self.status;
  end

  def get_loan_due_status(on_date = nil)
  end

  private

  def self.to_loan(for_amount, repayment_frequency, tenure, from_lending_product, for_borrower_id,
      administered_at_origin, accounted_at_origin, applied_on_date, scheduled_disbursal_date, scheduled_first_repayment_date,
      applied_by_staff, recorded_by_user, lan = nil)
    Validators::Arguments.not_nil?(for_amount, repayment_frequency, tenure, from_lending_product, for_borrower_id,
                                    administered_at_origin, accounted_at_origin, applied_on_date, scheduled_disbursal_date,
                                    scheduled_first_repayment_date, applied_by_staff, recorded_by_user)
    loan_hash = {}
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
    loan_hash[:lan]                            = lan if lan
    debugger
    Lending.new(loan_hash)
  end

  # Set the loan status
  def set_status(new_loan_status)
    raise Errors::InvalidStateChangeError, "Loan status is already #{new_loan_status}" if self.status == new_loan_status
    self.status = new_loan_status
    save
  end

  # All actions required to update the loan for the payment
  def update_for_payment(payment_transaction)
    #TBD
  end

  # Record an allocation on the loan for the given amount
  def make_allocation(amount, on_date = Date.today)
    #TBD
  end

end