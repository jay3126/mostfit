class ReportingFacade < StandardFacade

  def loans_applied_by_branches_on_date(at_branches_ary, on_date)
    loans_by_branches_for_status_on_date(at_branches_ary, :applied, on_date)
  end

  def loans_applied_by_centers_on_date(at_centers_ary, on_date)
    loans_by_centers_for_status_on_date(at_centers_ary, :applied, on_date)
  end

  def loans_approved_by_branches_on_date(at_branches_ary, on_date)
    loans_by_branches_for_status_on_date(at_branches_ary, :approved, on_date)
  end

  def loans_approved_by_centers_on_date(at_centers_ary, on_date)
    loans_by_centers_for_status_on_date(at_centers_ary, :approved, on_date)
  end

  def loans_scheduled_for_disbursement_by_branches_on_date(at_branches_ary, on_date)
    loans_by_branches_for_status_on_date(at_branches_ary, :scheduled_for_disbursement, on_date)
  end

  def loans_scheduled_for_disbursement_by_centers_on_date(at_centers_ary, on_date)
    loans_by_centers_for_status_on_date(at_centers_ary, :scheduled_for_disbursement, on_date)
  end
  
  def loans_disbursed_by_branches_on_date(at_branches_ary, on_date)
    loans_by_branches_for_status_on_date(at_branches_ary, :disbursed, on_date)
  end

  def loans_disbursed_by_centers_on_date(at_centers_ary, on_date)
    loans_by_centers_for_status_on_date(at_centers_ary, :disbursed, on_date)
  end

  def loans_by_branches_for_status_on_date(at_branches_ary, for_status, on_date)
    loan_status, date_to_query, amount_to_sum = LoanLifeCycle::STATUSES_DATES_SUM_AMOUNTS[for_status]
    query = Lending.all(:status => loan_status, :accounted_at_origin => at_branches_ary, date_to_query => on_date)
    count = query.count
    sum_amount = query.aggregate(amount_to_sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  def loans_by_centers_for_status_on_date(at_centers_ary, for_status, on_date)
    loan_status, date_to_query, amount_to_sum = LoanLifeCycle::STATUSES_DATES_SUM_AMOUNTS[for_status]
    query = Lending.all(:status => loan_status, :administered_at_origin => at_centers_ary, date_to_query => on_date)
    count = query.count
    sum_amount = query.aggregate(amount_to_sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  private

  def to_money_amount(amount)
    Money.new(amount, default_currency)
  end

  def zero_money_amount
    @zero_money_amount ||= MoneyManager.default_zero_money
  end

  def default_currency
    @default_currency ||= MoneyManager.get_default_currency
  end

  def loan_facade
    @loan_facade ||= FacadeFactory.instance.get_other_facade(FacadeFactory::LOAN_FACADE, self)
  end

  def location_facade
    @location_facade ||= FacadeFactory.instance.get_other_facade(FacadeFactory::LOCATION_FACADE, self)
  end

end
