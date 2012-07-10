class InsuranceClaim
  include DataMapper::Resource
  include Constants::Properties
  include Constants::Insurance

  property :id,              Serial
  property :claim_unique_id, *UNIQUE_ID
  property :filed_on,        *DATE_NOT_NULL
  property :claim_status,    Enum.send('[]', *INSURANCE_CLAIM_STATUSES)
  property :accounted_at,    *INTEGER_NOT_NULL
  property :performed_by,    *INTEGER_NOT_NULL
  property :recorded_by,     *INTEGER_NOT_NULL
  property :created_at,      *CREATED_AT

  belongs_to :death_event
  belongs_to :simple_insurance_policy

  def self.file_insurance_claim_for_death_event(death_event, claim_status, on_insurance_policy, filed_on_date, accounted_at_id, performed_by_id, recorded_by_id)
    claim_information = {}
    claim_information[:death_event]  = death_event
    claim_information[:claim_status] = claim_status
    claim_information[:simple_insurance_policy] = on_insurance_policy
    claim_information[:filed_on]     = filed_on_date
    claim_information[:accounted_at] = accounted_at_id
    claim_information[:performed_by] = performed_by_id
    claim_information[:recorded_by]  = recorded_by_id

    insurance_claim = create(claim_information)
    raise Errors::DataError, insurance_claim.errors.first.first unless insurance_claim.saved?
    insurance_claim
  end

end
