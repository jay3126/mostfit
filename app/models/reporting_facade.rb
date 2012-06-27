class ReportingFacade < StandardFacade
  include Constants::Transaction, Constants::Products

  # Transactions at locations on date

  # QUERIES
  #performed_at is nominally a center location
  #accounted_at is nominally a branch location
  
  def all_receipts_on_loans_performed_at_locations_on_value_date(on_date, *at_location_ids_ary)
    location_ids_array = *at_location_ids_ary.to_a
    query = PaymentTransaction.all(:effective_on => on_date, :receipt_type => RECEIPT, :on_product_type => LENDING, :performed_at => location_ids_array)
    count = query.count
    sum_amount = query.aggregate(:amount.sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  def all_receipts_on_loans_accounted_at_locations_on_value_date(on_date, *at_location_ids_ary)
    location_ids_array = *at_location_ids_ary.to_a
    query = PaymentTransaction.all(:effective_on => on_date, :receipt_type => RECEIPT, :on_product_type => LENDING, :accounted_at => location_ids_array)
    count = query.count
    sum_amount = query.aggregate(:amount.sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  def all_payments_on_loans_performed_at_locations_on_value_date(on_date, *at_location_ids_ary)
    location_ids_array = *at_location_ids_ary.to_a
    query = PaymentTransaction.all(:effective_on => on_date, :receipt_type => PAYMENT, :on_product_type => LENDING, :performed_at => location_ids_array)
    count = query.count
    sum_amount = query.aggregate(:amount.sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  def all_payments_on_loans_accounted_at_locations_on_value_date(on_date, *at_location_ids_ary)
    location_ids_array = *at_location_ids_ary.to_a
    query = PaymentTransaction.all(:effective_on => on_date, :receipt_type => PAYMENT, :on_product_type => LENDING, :accounted_at => location_ids_array)
    count = query.count
    sum_amount = query.aggregate(:amount.sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  def net_payments_on_loans_performed_at_locations_on_value_date(on_date, *at_location_ids_ary)
    payments = all_payments_on_loans_performed_at_locations_on_value_date(on_date, *at_location_ids_ary)
    receipts = all_receipts_on_loans_performed_at_locations_on_value_date(on_date, *at_location_ids_ary)

    total_payments_amount = payments[:total_amount]; total_receipts_amount = receipts[:total_amount]
    net_transaction_type = total_payments_amount > total_receipts_amount ? PAYMENT : RECEIPT
    net_amount = total_payments_amount - total_receipts_amount
    total_count = payments[:count] + receipts[:count]

    {:count => total_count, :total_amount => net_amount}
  end

  def net_payments_on_loans_accounted_at_locations_on_value_date(on_date, *at_location_ids_ary)
    payments = all_payments_on_loans_accounted_at_locations_on_value_date(on_date, *at_location_ids_ary)
    receipts = all_receipts_on_loans_accounted_at_locations_on_value_date(on_date, *at_location_ids_ary)

    total_payments_amount = payments[:total_amount]; total_receipts_amount = receipts[:total_amount]
    net_transaction_type = total_payments_amount > total_receipts_amount ? PAYMENT : RECEIPT
    net_amount = total_payments_amount - total_receipts_amount
    total_count = payments[:count] + receipts[:count]

    {:count => total_count, :total_amount => net_amount}
  end

  # Loans by status at locations on date

  def loans_applied_by_branches_on_date(on_date, *at_branch_ids_ary)
    loans_by_branches_for_status_on_date(:applied, on_date, *at_branch_ids_ary)
  end

  def loans_applied_by_centers_on_date(on_date, *at_center_ids_ary)
    loans_by_centers_for_status_on_date(:applied, on_date, *at_center_ids_ary)
  end

  def loans_approved_by_branches_on_date(on_date, *at_branch_ids_ary)
    loans_by_branches_for_status_on_date(:approved, on_date, *at_branch_ids_ary)
  end

  def loans_approved_by_centers_on_date(on_date, *at_center_ids_ary)
    loans_by_centers_for_status_on_date(:approved, on_date, *at_center_ids_ary)
  end

  def loans_scheduled_for_disbursement_by_branches_on_date(on_date, *at_branch_ids_ary)
    loans_by_branches_for_status_on_date(:scheduled_for_disbursement, on_date, *at_branch_ids_ary)
  end

  def loans_scheduled_for_disbursement_by_centers_on_date(on_date, *at_center_ids_ary)
    loans_by_centers_for_status_on_date(:scheduled_for_disbursement, on_date, *at_center_ids_ary)
  end
  
  def loans_disbursed_by_branches_on_date(on_date, *at_branch_ids_ary)
    loans_by_branches_for_status_on_date(:disbursed, on_date, *at_branch_ids_ary)
  end

  def loans_disbursed_by_centers_on_date(on_date, *at_center_ids_ary)
    loans_by_centers_for_status_on_date(:disbursed, on_date, *at_center_ids_ary)
  end

  def loans_by_branches_for_status_on_date(for_status, on_date, *at_branch_ids_ary)
    loan_status, date_to_query, amount_to_sum = LoanLifeCycle::STATUSES_DATES_SUM_AMOUNTS[for_status]
    branches_array = *at_branch_ids_ary.to_a
    query = Lending.all(:status => loan_status, date_to_query => on_date, :accounted_at_origin => branches_array)
    count = query.count
    sum_amount = query.aggregate(amount_to_sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  def loans_by_centers_for_status_on_date(for_status, on_date, *at_center_ids_ary)
    loan_status, date_to_query, amount_to_sum = LoanLifeCycle::STATUSES_DATES_SUM_AMOUNTS[for_status]
    centers_array = *at_center_ids_ary.to_a
    query = Lending.all(:status => loan_status, date_to_query => on_date, :administered_at_origin => centers_array)
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
