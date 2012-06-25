class ChoiceFacade < StandardFacade

  # This is a list of all the locations (across various levels in the hierarchy) that is visible to the staff on the specified date
  def visible_locations(for_staff_id, on_date = Date.today)
    location_facade.visible_locations(for_staff_id, on_date)
  end

  def available_loan_products(on_date = Date.today)
    configuration_facade.available_loan_products(on_date)
  end

  private

  def location_facade
    @location_facade ||= FacadeFactory.instance.get_other_facade(FacadeFactory::LOCATION_FACADE, self)
  end

  def user_facade
    @user_facade ||= FacadeFactory.instance.get_other_facade(FacadeFactory::USER_FACADE, self)
  end

  def configuration_facade
    @configuration_facade ||= FacadeFactory.instance.get_other_facade(FacadeFactory::CONFIGURATION_FACADE, self)
  end

end