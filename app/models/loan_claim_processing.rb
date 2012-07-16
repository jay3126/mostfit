class LoanClaimProcessing
  include DataMapper::Resource
  include Constants::Properties
  include Comparable

  property :id,                           Serial
  property :commenced_on,                 *DATE_NOT_NULL
  property :processing_status,            Enum.send('[]', *Constants::Loan::LOAN_CLAIM_PROCESSING_STATUSES), :nullable => false, :default => Constants::Loan::DEFAULT_LOAN_CLAIM_PROCESSING_STATUS
  property :processing_completion_status, Enum.send('[]', *Constants::Loan::LOAN_CLAIM_PROCESSING_COMPLETION_STATUSES), :nullable => false, :default => Constants::Loan::DEFAULT_LOAN_CLAIM_PROCESSING_COMPLETION_STATUS
  property :processing_completed_on,      *DATE
  property :created_at,                   *CREATED_AT
  property :updated_at,                   *UPDATED_AT

  belongs_to :lending
  belongs_to :death_event

  def created_on; self.commenced_on; end

  def <=>(other)
    other.respond_to?(:created_on) ? (self.created_on <=> other.created_on) : nil
  end

  def self.register_loan_claim(for_death_event, on_loan, on_date)
    Validators::Arguments.not_nil?(for_death_event, on_loan, on_date)
    loan_claim_info = {}
    loan_claim_info[:death_event]  = for_death_event
    loan_claim_info[:lending]      = on_loan
    loan_claim_info[:commenced_on] = on_date
    loan_claim_info[:processing_status]            = Constants::Loan::DEFAULT_LOAN_CLAIM_PROCESSING_STATUS
    loan_claim_info[:processing_completion_status] = Constants::Loan::DEFAULT_LOAN_CLAIM_PROCESSING_COMPLETION_STATUS

    claim = create(loan_claim_info)
    raise Errors::DataError, claim.errors.first.first unless claim.saved?
    claim
  end

end
