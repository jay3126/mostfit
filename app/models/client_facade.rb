class ClientFacade < StandardFacade

  # Administered at corresponds to the location that interactions with the client take place
  # (Centers as per the older scheme)
  def get_clients_administered(at_location_id, on_date)
    ClientAdministration.get_clients_administered(at_location_id, on_date)
  end

  # Registered at corresponds to the office location that the clients belong to
  # (Branches as per the older scheme)
  def get_clients_registered(at_location_id, on_date)
    ClientAdministration.get_clients_registered(at_location_id, on_date)
  end

  def get_all_loans_for_counterparty(client)
    LoanBorrower.get_all_loans_for_counterparty(client)
  end

  def get_administration_on_date(counterparty, on_date)
    ClientAdministration.get_administration_on_date(counterparty, on_date)
  end
  
  def number_of_loans_for_counterparty_till_date(counterparty, on_date = Date.today)
    LoanBorrower.number_of_loans_for_counterparty_till_date(counterparty, on_date)
  end

  def number_of_outstanding_loans_for_counterparty_on_date(counterparty, on_date = Date.today)
    LoanBorrower.number_of_oustanding_loans_for_counterparty_on_date(counterparty, on_date)
  end

  def has_death_event?(client)
    ClientAdministration.has_death_event?(client)
  end

end
