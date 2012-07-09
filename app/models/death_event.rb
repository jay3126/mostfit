class DeathEvent
  include DataMapper::Resource
  include Constants::Properties
  include Constants::Masters

  property :id,                     Serial
  property :deceased_name,          *NAME
  property :relationship_to_client, Enum.send('[]', *DECEASED_PERSON_RELATIONSHIPS)
  property :date_of_death,          *DATE_NOT_NULL
  property :reported_on,            *DATE_NOT_NULL
  property :reported_by,            *INTEGER_NOT_NULL
  property :recorded_by,            *INTEGER_NOT_NULL
  property :created_at,             *CREATED_AT

  belongs_to :affected_client, 'Client', :parent_key => [:id], :child_key => [:affected_client_id]
  has n, :insurance_claims

end
