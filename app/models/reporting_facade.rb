class ReportingFacade < StandardFacade
  include Constants::Transaction, Constants::Products

  # Allocations

  def total_loan_allocation_receipts_accounted_at_locations_on_value_date(on_date, *at_location_ids_ary)
    total_loan_allocation_receipts_at_locations_on_value_date(on_date, TRANSACTION_ACCOUNTED_AT, at_location_ids_ary)
  end

  def total_loan_allocation_receipts_performed_at_locations_on_value_date(on_date, *at_location_ids_ary)
    total_loan_allocation_receipts_at_locations_on_value_date(on_date, TRANSACTION_PERFORMED_AT, at_location_ids_ary)
  end

  # Outstanding loan IDs by location

  def all_outstanding_loan_ids_accounted_at_locations_on_date(on_date, *at_location_ids_ary)
    all_outstanding_loan_ids_at_locations_on_date(on_date, Constants::Loan::ACCOUNTED_AT, at_location_ids_ary)
  end

  def all_outstanding_loan_ids_administered_at_locations_on_date(on_date, *at_location_ids_ary)
    all_outstanding_loan_ids_at_locations_on_date(on_date, Constants::Loan::ADMINISTERED_AT, at_location_ids_ary)
  end

  def all_outstanding_loans_on_date(on_date = Date.today)
    Lending.all.select{|loan| loan.is_outstanding_on_date?(on_date)}
  end

  # Outstanding loan balances

  def sum_all_outstanding_loans_balances_accounted_at_locations_on_date(on_date, *at_location_ids_ary)
    balances_grouped_by_location = all_outstanding_loans_balances_accounted_at_locations_on_date(on_date, at_location_ids_ary)
    sum_of_balances_by_location = {}
    balances_grouped_by_location.each { |at_location_id, balances_map|
      sum_of_balances_by_location[at_location_id] = Money.add_money_hash_values(MoneyManager.get_default_currency, *balances_map.values)
    }
    sum_of_balances_by_location
  end

  def sum_all_outstanding_loans_balances_administered_at_locations_on_date(on_date, *at_location_ids_ary)
    balances_grouped_by_location = all_outstanding_loans_balances_administered_at_locations_on_date(on_date, at_location_ids_ary)
    sum_of_balances_by_location = {}
    balances_grouped_by_location.each { |at_location_id, balances_map|
      sum_of_balances_by_location[at_location_id] = Money.add_money_hash_values(MoneyManager.get_default_currency, *balances_map.values)
    }
    sum_of_balances_by_location
  end

  def all_outstanding_loans_balances_accounted_at_locations_on_date(on_date, *at_location_ids_ary)
    all_outstanding_loans_balances_at_locations_on_date(on_date, Constants::Loan::ACCOUNTED_AT, at_location_ids_ary)
  end

  def all_outstanding_loans_balances_administered_at_locations_on_date(on_date, *at_location_ids_ary)
    all_outstanding_loans_balances_at_locations_on_date(on_date, Constants::Loan::ADMINISTERED_AT, at_location_ids_ary)
  end

  def loan_balances_for_loan_ids_on_date(on_date, *for_loan_ids_ary)
    loan_ids_array = *for_loan_ids_ary.to_a
    loan_balances_by_loan_id = {}
    loan_ids_array.each { |for_loan_id|
      due_status_record = LoanDueStatus.most_recent_status_record_on_date(for_loan_id, on_date)
      loan_balances_by_loan_id[for_loan_id] = due_status_record.to_money if due_status_record
    }
    loan_balances_by_loan_id
  end

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
    net_amount = Money.net_amount(total_payments_amount, total_receipts_amount)
    total_count = payments[:count] + receipts[:count]

    {:count => total_count, :total_amount => net_amount}
  end

  # Loans by status at locations on date

  def loans_applied_by_branches_on_date(on_date, *at_branch_ids_ary)
    aggregate_loans_by_branches_for_status_on_date(:applied, on_date, *at_branch_ids_ary)
  end

  def loans_applied_by_centers_on_date(on_date, *at_center_ids_ary)
    loans_by_centers_for_status_on_date(:applied, on_date, *at_center_ids_ary)
  end

  def loans_approved_by_branches_on_date(on_date, *at_branch_ids_ary)
    aggregate_loans_by_branches_for_status_on_date(:approved, on_date, *at_branch_ids_ary)
  end

  def loans_approved_by_centers_on_date(on_date, *at_center_ids_ary)
    loans_by_centers_for_status_on_date(:approved, on_date, *at_center_ids_ary)
  end

  def loans_scheduled_for_disbursement_by_branches_on_date(on_date, *at_branch_ids_ary)
    aggregate_loans_by_branches_for_status_on_date(:scheduled_for_disbursement, on_date, *at_branch_ids_ary)
  end

  def loans_scheduled_for_disbursement_by_centers_on_date(on_date, *at_center_ids_ary)
    loans_by_centers_for_status_on_date(:scheduled_for_disbursement, on_date, *at_center_ids_ary)
  end

  def individual_loans_disbursed_by_branches_on_date(on_date, *at_branch_ids_ary)
    individual_loans_by_branches_for_status_on_date(:disbursed, on_date, *at_branch_ids_ary)
  end

  def loans_disbursed_by_branches_on_date(on_date, *at_branch_ids_ary)
    aggregate_loans_by_branches_for_status_on_date(:disbursed, on_date, *at_branch_ids_ary)
  end

  def individual_loans_disbursed_by_centers_on_date(on_date, *at_center_ids_ary)
    individual_loans_by_centers_for_status_on_date(:disbursed, on_date, *at_center_ids_ary)
  end

  def loans_disbursed_by_centers_on_date(on_date, *at_center_ids_ary)
    loans_by_centers_for_status_on_date(:disbursed, on_date, *at_center_ids_ary)
  end
  
  private

  def individual_loans_by_branches_for_status_on_date(for_status, on_date, *at_branch_ids_ary)
    loan_status, date_to_query, ignore_val = LoanLifeCycle::STATUSES_DATES_SUM_AMOUNTS[for_status]
    query = {:status => loan_status, date_to_query => on_date}
    query[:accounted_at_origin] = at_branch_ids_ary if (at_branch_ids_ary and (not(at_branch_ids_ary.empty?)))
    all_loans = Lending.all(query)
    # TODO: must be changed for loan administration
    all_loans.group_by {|loan| loan.accounted_at_origin}
  end

  def individual_loans_by_centers_for_status_on_date(for_status, on_date, *at_center_ids_ary)
    loan_status, date_to_query, ignore_val = LoanLifeCycle::STATUSES_DATES_SUM_AMOUNTS[for_status]
    query = {:status => loan_status, date_to_query => on_date}
    query[:administered_at_origin] = at_center_ids_ary if (at_center_ids_ary and (not(at_center_ids_ary.empty?)))
    all_loans = Lending.all(query)
    # TODO: must be changed for loan administration
    all_loans.group_by {|loan| loan.administered_at_origin}
  end

  def aggregate_loans_by_branches_for_status_on_date(for_status, on_date, *at_branch_ids_ary)
    loan_status, date_to_query, amount_to_sum = LoanLifeCycle::STATUSES_DATES_SUM_AMOUNTS[for_status]
    query = {:status => loan_status, date_to_query => on_date}
    query[:accounted_at_origin] = at_branch_ids_ary if (at_branch_ids_ary and (not (at_branch_ids_ary.empty?)))
    query_results = Lending.all(query)

    count = query_results.count
    sum_amount = query_results.aggregate(amount_to_sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  def loans_by_centers_for_status_on_date(for_status, on_date, *at_center_ids_ary)
    loan_status, date_to_query, amount_to_sum = LoanLifeCycle::STATUSES_DATES_SUM_AMOUNTS[for_status]
    query = {:status => loan_status, date_to_query => on_date}
    query[:administered_at_origin] = at_center_ids_ary if (at_center_ids_ary and (not (at_center_ids_ary.empty?)))
    query_results = Lending.all(query)

    count = query_results.count
    sum_amount = query_results.aggregate(amount_to_sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  def total_loan_allocation_receipts_at_locations_on_value_date(on_date, performed_or_accounted_choice, *at_location_ids_ary)
    total_loan_allocation_receipts_grouped_by_location = {}
    property_sym = TRANSACTION_LOCATIONS[performed_or_accounted_choice]
    at_location_ids_ary.each { |at_location_id|
      all_loan_receipts_at_location = LoanReceipt.all(:effective_on => on_date, property_sym => at_location_id)
      total_loan_allocation_receipts_grouped_by_location[at_location_id] = LoanReceipt.add_up(all_loan_receipts_at_location)
    }
    total_loan_allocation_receipts_grouped_by_location
  end

  def all_outstanding_loans_balances_at_locations_on_date(on_date, accounted_or_administered_choice, *at_location_ids_ary)
    location_ids_array = *at_location_ids_ary.to_a
    all_loan_balances_grouped_by_location = {}
    all_loans_grouped_by_location = all_outstanding_loan_ids_at_locations_on_date(on_date, accounted_or_administered_choice, *at_location_ids_ary)
    all_loans_grouped_by_location.each { |at_location_id, for_loan_ids_ary|
      all_loan_balances_grouped_by_location[at_location_id] = loan_balances_for_loan_ids_on_date(on_date, for_loan_ids_ary)
    }
    all_loan_balances_grouped_by_location
  end

  def all_outstanding_loan_ids_at_locations_on_date(on_date, accounted_or_administered_choice, *at_location_ids_ary)
    location_ids_array = *at_location_ids_ary.to_a
    all_loan_ids_grouped_by_location = {}
    location_ids_array.each { |at_location_id|
      all_loans_at_location = []
      case accounted_or_administered_choice
        when Constants::Loan::ACCOUNTED_AT then all_loans_at_location = LoanAdministration.get_loans_accounted(at_location_id, on_date)
        when Constants::Loan::ADMINISTERED_AT then all_loans_at_location = LoanAdministration.get_loans_administered(at_location_id, on_date)
        else raise ArgumentError, "Please specify whether loans accounted or loans administered are needed"
      end
      all_outstanding_loans_at_location = all_loans_at_location.select {|loan| loan.is_outstanding_on_date?(on_date)}
      all_loan_ids_grouped_by_location[at_location_id] = get_ids(all_outstanding_loans_at_location)
    }
    all_loan_ids_grouped_by_location
  end

  def to_money_amount(amount)
    Money.new(amount.to_i, default_currency)
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

  def get_ids(collection)
    raise ArgumentError, "Collection does not appear to be enumerable" unless collection.is_a?(Enumerable)
    collection.collect {|element| element.id}
  end

end
