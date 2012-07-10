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

  def self.save_death_event(deceased_name, relationship_to_client, date_of_death_str, reported_on_str, reported_on, recorded_by, reported_by, affected_client_id)
    death_event_hash = {}
    death_event_hash[:deceased_name] = deceased_name
    death_event_hash[:relationship_to_client] = relationship_to_client
    death_event_hash[:date_of_death] = date_of_death_str
    death_event_hash[:reported_on] = reported_on_str
    death_event_hash[:reported_on]  = reported_on
    death_event_hash[:recorded_by] = recorded_by
    death_event_hash[:reported_by] = reported_by
    death_event_hash[:affected_client_id] = affected_client_id
    death_event = create(death_event_hash)
    raise Errors::DataError, death_event.errors.first.first unless death_event.saved?
    death_event
  end

end
