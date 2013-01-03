class ClientAdministration
  include DataMapper::Resource
  include Constants::Properties, Constants::Transaction

  property :id,                Serial
  property :counterparty_type, Enum.send('[]', *COUNTERPARTIES), :nullable => false
  property :counterparty_id,   *INTEGER_NOT_NULL
  property :administered_at,   *INTEGER_NOT_NULL
  property :registered_at,     *INTEGER_NOT_NULL
  property :effective_on,      *DATE_NOT_NULL
  property :performed_by,      *INTEGER_NOT_NULL
  property :recorded_by,       *INTEGER_NOT_NULL
  property :created_at,        *CREATED_AT

  def counterparty; Resolver.fetch_counterparty(self.counterparty_type, self.counterparty_id); end
  def administered_at_location; BizLocation.get(self.administered_at); end
  def registered_at_location; BizLocation.get(self.registered_at); end
  def performed_by_staff; StaffMember.get(self.performed_by); end
  def recorded_by_user; User.get(self.recorded_by); end

  validates_with_method :assignment_and_creation_dates_are_valid?
  validates_with_method :can_only_assign_to_one_set_of_locations_on_date?
  validates_with_method :counterparty_is_active?

  def assignment_and_creation_dates_are_valid?
    Validators::Assignments.is_valid_assignment_date?(effective_on, counterparty, administered_at_location, registered_at_location)
  end

  def can_only_assign_to_one_set_of_locations_on_date?
    administered_at_on_date = ClientAdministration.first(:counterparty_type => self.counterparty_type, :counterparty_id => self.counterparty_id, :administered_at => self.administered_at, :effective_on => self.effective_on)
    registered_at_on_date = ClientAdministration.first(:counterparty_type => self.counterparty_type, :counterparty_id => self.counterparty_id, :registered_at => self.registered_at, :effective_on => self.effective_on)
    (administered_at_on_date or registered_at_on_date) ? [false, "The client is already assigned to location on the same date: #{effective_on}"] :
      true
  end

  def counterparty_is_active?
    if self.counterparty
      validate_value = self.counterparty.active ? true :
        [false, "Inactive client cannot be re-assigned"]
      return validate_value
    end
    true
  end

  # Assign the administered_at and registered_at BizLocation instances to the counterparty performed by staff and recorded by user on the specified effective date
  def self.assign(administered_at, registered_at, to_counterparty, performed_by, recorded_by, effective_on = Date.today)
    raise ArgumentError, "Locations to be assigned must be instances of BizLocation" unless (administered_at.is_a?(BizLocation) and registered_at.is_a?(BizLocation))
    raise ArgumentError, "#{to_counterparty.class} provided for assignment is not a valid counterparty" unless Resolver.is_a_counterparty?(to_counterparty)
    assignment                         = { }
    assignment[:administered_at]       = administered_at.id
    assignment[:registered_at]         = registered_at.id
    counterparty_type, counterparty_id = Resolver.resolve_counterparty(to_counterparty)
    assignment[:counterparty_type]     = counterparty_type
    assignment[:counterparty_id]       = counterparty_id
    assignment[:effective_on]          = effective_on
    assignment[:performed_by]          = performed_by
    assignment[:recorded_by]           = recorded_by
    client_administration              = create(assignment)
    raise Errors::DataError, client_administration.errors.first.first unless client_administration.saved?
    client_administration
  end

  # Gets the BizLocation that the counterparty is administered at on the specified date
  def self.get_administered_at(counterparty, on_date = Date.today)
    locations = get_locations(counterparty, on_date)
    locations ? locations[COUNTERPARTY_ADMINISTERED_AT] : nil
  end

  # Gets the BizLocation that the counterparty is registered at on the specified date
  def self.get_registered_at(counterparty, on_date = Date.today)
    locations = get_locations(counterparty, on_date)
    locations ? locations[COUNTERPARTY_REGISTERED_AT] : nil
  end

  # For each ClientAdministration, this returns a map with the administered and registered locations as values
  def to_location_map
    {
      COUNTERPARTY_ADMINISTERED_AT => administered_at_location,
      COUNTERPARTY_REGISTERED_AT   => registered_at_location
    }
  end

  # Gets the locations for the counterparty on the specified date
  def self.get_locations(for_counterparty, on_date = Date.today)
    recent_assignment = get_administration_on_date(for_counterparty, on_date)
    recent_assignment ? recent_assignment.to_location_map : nil
  end

  def self.get_current_administration(for_counterparty)
    counterparty_type, counterparty_id = Resolver.resolve_counterparty(for_counterparty)
    current_query = {}
    current_query[:counterparty_type] = counterparty_type
    current_query[:counterparty_id]   = counterparty_id
    current_query[:order]             = [:effective_on.desc]
    first(current_query)
  end

  def self.get_administration_on_date(for_counterparty, on_date = Date.today)
    counterparty_type, counterparty_id = Resolver.resolve_counterparty(for_counterparty)
    current_query = {}
    current_query[:counterparty_type] = counterparty_type
    current_query[:counterparty_id]   = counterparty_id
    current_query[:effective_on.lte]  = on_date
    current_query[:order]             = [:effective_on.desc]
    first(current_query)
  end

  def self.get_counterparty_administration(for_counterparty)
    counterparty_type, counterparty_id = Resolver.resolve_counterparty(for_counterparty)
    current_query = {}
    current_query[:counterparty_type] = counterparty_type
    current_query[:counterparty_id]   = counterparty_id
    current_query[:order]             = [:effective_on.desc]
    all(current_query)
  end

  # Returns a list of client instances that are administered at the specified location (by ID) on the specified date
  def self.get_clients_administered(at_location_id, on_date = Date.today)
    get_clients_at_location(COUNTERPARTY_ADMINISTERED_AT, at_location_id, on_date)
  end

  def self.get_client_ids_administered_by_sql(at_location_id, on_date = Date.today, count = false)
    get_clients_at_location_by_sql(COUNTERPARTY_ADMINISTERED_AT, at_location_id, on_date, count)
  end

  def self.get_clients_administered_by_sql(at_location_id, on_date = Date.today, count = false)
    client_ids = get_clients_at_location_by_sql(COUNTERPARTY_ADMINISTERED_AT, at_location_id, on_date, count)
    client_ids.blank? ? [] : Client.all(:id => client_ids)
  end

  # Returns a list of client instances that are registered at the specified location (by ID) on the specified date
  def self.get_clients_registered(at_location_id, on_date = Date.today)
    get_clients_at_location(COUNTERPARTY_REGISTERED_AT, at_location_id, on_date)
  end

  def self.get_client_ids_registered_by_sql(at_location_id, on_date = Date.today, count = false)
    get_clients_at_location_by_sql(COUNTERPARTY_REGISTERED_AT, at_location_id, on_date, count)
  end

  def self.get_clients_registered_by_sql(at_location_id, on_date = Date.today, count = false)
    client_ids = get_clients_at_location_by_sql(COUNTERPARTY_REGISTERED_AT, at_location_id, on_date, count)
    client_ids.blank? ? [] : Client.all(:id => client_ids)
  end

  def self.has_death_event?(client)
    return client.death_event.blank? ? false : true
  end

  private

  # Returns a list of client instances that are administered at or registered at the specified location (by ID) on the specified date
  def self.get_clients_at_location(administered_or_registered_choice, given_location_id, on_date = Date.today)
    clients                                      = []
    locations                                    = { }
    locations[administered_or_registered_choice] = given_location_id
    locations[:counterparty_type]                = Constants::Transaction::CLIENT
    locations[:effective_on.lte]                 = on_date
    administration                               = all(locations)

    all_clients = (administration.collect {|admin_instance| admin_instance.counterparty}).uniq

    all_clients.each { |client|
      current_administration = get_locations(client, on_date)
      if administered_or_registered_choice == COUNTERPARTY_ADMINISTERED_AT
        administered_at = current_administration[COUNTERPARTY_ADMINISTERED_AT]
        clients.push(client) if (administered_at and (administered_at.id == given_location_id))
      end

      if administered_or_registered_choice == COUNTERPARTY_REGISTERED_AT
        registered_at = current_administration[COUNTERPARTY_REGISTERED_AT]
        clients.push(client) if (registered_at and (registered_at.id == given_location_id))
      end
    }
    clients.uniq
  end

  def self.get_clients_at_location_by_sql(administered_or_registered_choice, given_location_id, on_date = Date.today, count = false)
    locations                                    = { }
    locations[administered_or_registered_choice] = given_location_id.class == Array ? given_location_id : [given_location_id]
    locations[:counterparty_type]                = Constants::Transaction::CLIENT
    locations[:effective_on.lte]                 = on_date
    client_ids                                   = all(locations).aggregate(:counterparty_id)
    if client_ids.blank?
      count == true ? 0 : []
    else
      if count
        l_links = repository(:default).adapter.query("select count(*) from (select * from client_administrations where counterparty_type = 1 AND counterparty_id IN (#{client_ids.join(',')})) ca where #{administered_or_registered_choice} = (select #{administered_or_registered_choice} from client_administrations ca1 where ca.counterparty_id = ca1.counterparty_id and ca.counterparty_type = 1 and ca.#{administered_or_registered_choice} IN (#{locations[administered_or_registered_choice].join(',')}) order by ca1.effective_on desc limit 1 );")
        l_links.blank? ? 0 : l_links
      else
        client_ids = repository(:default).adapter.query("select ca.counterparty_id from (select * from client_administrations where counterparty_type = 1 AND counterparty_id IN (#{client_ids.join(',')})) ca where #{administered_or_registered_choice} = (select #{administered_or_registered_choice} from client_administrations ca1 where ca.counterparty_id = ca1.counterparty_id and ca.counterparty_type = 1 and ca.#{administered_or_registered_choice} IN (#{locations[administered_or_registered_choice].join(',')}) order by ca1.effective_on desc limit 1 );")
        client_ids.blank? ? [] : client_ids
      end
    end
  end

end
