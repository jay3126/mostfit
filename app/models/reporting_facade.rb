class ReportingFacade < StandardFacade

  AGGREGATE_BY_BRANCH = :aggregate_by_branch
  AGGREGATE_BY_CENTER = :aggregate_by_center
  AGGREGATE_BY_CLIENT = :aggregate_by_client
  AGGREGATE_BY_LOAN   = :aggregate_by_loan

  def aggregate_loans_applied(aggregate_by, on_date)
    loan_facade.aggregate_loans_applied(aggregate_by, on_date)
  end

  def aggregate_loans_scheduled_for_disbursement(aggregate_by, on_date)
    loan_facade.aggregate_loans_scheduled_for_disbursement(aggregate_by, on_date)
  end

  private

  def loan_facade
    @loan_facade ||= FacadeFactory.instance.get_other_facade(FacadeFactory::LOAN_FACADE, self)
  end

  def location_facade
    @location_facade ||= FacadeFactory.instance.get_other_facade(FacadeFactory::LOCATION_FACADE, self)
  end

end
