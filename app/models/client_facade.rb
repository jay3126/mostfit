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

end
