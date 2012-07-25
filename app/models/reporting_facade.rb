class ReportingFacade < StandardFacade
  include Constants::Transaction, Constants::Products

  # Loans scheduled to repay on date

  def all_outstanding_loans_scheduled_on_date(on_date = Date.today)
    outstanding_loans = all_outstanding_loans_on_date(on_date)
    outstanding_loans.select {|loan| loan.schedule_date?(on_date)}
  end

  def all_oustanding_loans_scheduled_on_date_with_advance_balances(on_date = Date.today)
    outstanding_scheduled_on_date = all_outstanding_loans_scheduled_on_date(on_date)
    outstanding_scheduled_on_date.select {|loan| (loan.advance_balance(on_date) > loan.zero_money_amount)}
  end

  def all_oustanding_loan_IDs_scheduled_on_date_with_advance_balances(on_date = Date.today)
    get_ids(all_oustanding_loans_scheduled_on_date_with_advance_balances(on_date))
  end

  # Allocations

  def total_loan_allocation_receipts_accounted_at_locations_on_value_date(on_date, *at_location_ids_ary)
    total_loan_allocation_receipts_at_locations_on_value_date(on_date, TRANSACTION_ACCOUNTED_AT, at_location_ids_ary)
  end

  #this method is to find out total loan allocation accounted at a particular location for a date range specified.
  def total_loan_allocation_receipts_accounted_at_locations_for_date_range(on_date, till_date, *at_location_ids_ary)
    total_loan_allocation_receipts_at_locations_for_date_range(on_date, till_date, TRANSACTION_ACCOUNTED_AT, at_location_ids_ary)
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
  
  def all_outstanding_loan_IDs_on_date(on_date = Date.today)
    get_ids(all_outstanding_loans_on_date(on_date))
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

  #this is the method to find out outstanding loans_balances for a date range.
  def sum_all_outstanding_loans_balances_accounted_at_locations_for_date_range(on_date, till_date, *at_location_ids_ary)
    balances_grouped_by_location = all_outstanding_loans_balances_accounted_at_locations_for_date_range(on_date, till_date, at_location_ids_ary)
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

  #method to get all outstanding loan_balances accounted_at locations for date range.
  def all_outstanding_loans_balances_accounted_at_locations_for_date_range(on_date, till_date, *at_location_ids_ary)
    all_outstanding_loans_balances_at_locations_for_date_range(on_date, till_date, Constants::Loan::ACCOUNTED_AT, at_location_ids_ary)
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

  #this method id to find out loan_balances for loan_ids for a date range.
  def loan_balances_for_loan_ids_for_date_range(on_date, *for_loan_ids_ary)
    loan_ids_array = *for_loan_ids_ary.to_a
    loan_balances_by_loan_id = {}
    loan_ids_array1 = loan_ids_array.uniq
    if (loan_ids_array1 and (not loan_ids_array1.empty?))
      loan_ids_array1.each { |for_loan_id|
        due_status_record = LoanDueStatus.most_recent_status_record_on_date(for_loan_id, on_date)
        loan_balances_by_loan_id[for_loan_id] = due_status_record.to_money if due_status_record
      }
    end
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

  #this method is to find out loan_receipts accounted at location for a specified date range.
  def all_receipts_on_loans_accounted_at_locations_for_date_range(on_date, till_date, *at_location_ids_ary)
    location_ids_array = *at_location_ids_ary.to_a
    query = PaymentTransaction.all(:effective_on.gte => on_date, :effective_on.lte => till_date, :receipt_type => RECEIPT, :on_product_type => LENDING, :accounted_at => location_ids_array)
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

  #this method is to find out payments on loans accounted_at locations in a specified date range.
  def all_payments_on_loans_accounted_at_locations_for_date_range(on_date, till_date, *at_location_ids_ary)
    location_ids_array = *at_location_ids_ary.to_a
    query = PaymentTransaction.all(:effective_on.gte => on_date, :effective_on.lte => till_date, :receipt_type => PAYMENT, :on_product_type => LENDING, :accounted_at => location_ids_array)
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

  #this method is for calculating new payments on loans accounted at locations in a specified date range.
  def net_payments_on_loans_accounted_at_locations_for_date_range(on_date, till_date, *at_location_ids_ary)
    payments = all_payments_on_loans_accounted_at_locations_for_date_range(on_date, till_date, *at_location_ids_ary)
    receipts = all_receipts_on_loans_accounted_at_locations_for_date_range(on_date, till_date, *at_location_ids_ary)

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

  #This is the method to find out the loans applied by branches in a date range.
  def loans_applied_by_branches_for_date_range(on_date, till_date, *at_branch_ids_ary)
    aggregate_loans_by_branches_for_status_during_a_date_range(:applied, on_date, till_date, *at_branch_ids_ary)
  end

  def loans_applied_by_centers_on_date(on_date, *at_center_ids_ary)
    loans_by_centers_for_status_on_date(:applied, on_date, *at_center_ids_ary)
  end

  def loans_approved_by_branches_on_date(on_date, *at_branch_ids_ary)
    aggregate_loans_by_branches_for_status_on_date(:approved, on_date, *at_branch_ids_ary)
  end

  #This method is to find out loans approved by branches in a date range.
  def loans_approved_by_branches_for_date_range(on_date, till_date, *at_branch_ids_ary)
    aggregate_loans_by_branches_for_status_during_a_date_range(:approved, on_date, till_date, *at_branch_ids_ary)
  end

  def loans_approved_by_centers_on_date(on_date, *at_center_ids_ary)
    loans_by_centers_for_status_on_date(:approved, on_date, *at_center_ids_ary)
  end

  def loans_scheduled_for_disbursement_by_branches_on_date(on_date, *at_branch_ids_ary)
    aggregate_loans_by_branches_for_status_on_date(:scheduled_for_disbursement, on_date, *at_branch_ids_ary)
  end

  #this is the method to find out the loans scheduled for disbursement by branches in a date range.
  def loans_scheduled_for_disbursement_by_branches_for_date_range(on_date, till_date, *at_branch_ids_ary)
    aggregate_loans_by_branches_for_status_during_a_date_range(:scheduled_for_disbursement, on_date, till_date, *at_branch_ids_ary)
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

  #this is the method to find out loans disbursed by branches for a date range.
  def loans_disbursed_by_branches_for_date_range(on_date, till_date, *at_branch_ids_ary)
    aggregate_loans_by_branches_for_status_during_a_date_range(:disbursed, on_date, till_date, *at_branch_ids_ary)
  end

  def loans_disbursed_by_branches_and_lending_products_on_date(on_date, lending_product_list, *at_branch_ids_ary)
    aggregate_loans_by_branches_and_lending_products_for_status_on_date(:disbursed, on_date, lending_product_list, *at_branch_ids_ary)
  end

  def individual_loans_disbursed_by_centers_on_date(on_date, *at_center_ids_ary)
    individual_loans_by_centers_for_status_on_date(:disbursed, on_date, *at_center_ids_ary)
  end

  def loans_disbursed_by_centers_on_date(on_date, *at_center_ids_ary)
    loans_by_centers_for_status_on_date(:disbursed, on_date, *at_center_ids_ary)
  end

  def all_aggregate_fee_receipts_by_branches(on_date, till_date = on_date, *at_branch_ids_ary)
    from_date, to_date = Constants::Time.ordered_dates(on_date, till_date)
    query = {:effective_on.gte => from_date, :effective_on.lte => to_date}
    query[:accounted_at] = at_branch_ids_ary if (at_branch_ids_ary and (not (at_branch_ids_ary.empty?)))
    query_results = FeeReceipt.all(query)

    count = query_results.count
    sum_amount = query_results.aggregate(:fee_amount.sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  def aggregate_fee_receipts_on_loans_by_branches(on_date, till_date = on_date, *at_branch_ids_ary)
    from_date, to_date = Constants::Time.ordered_dates(on_date, till_date)
    query = {:effective_on.gte => from_date, :effective_on.lte => to_date}
    query[:fee_applied_on_type] = Constants::Fee::FEE_ON_LOAN
    query[:accounted_at] = at_branch_ids_ary if (at_branch_ids_ary and (not (at_branch_ids_ary.empty?)))
    query_results = FeeReceipt.all(query)

    count = query_results.count
    sum_amount = query_results.aggregate(:fee_amount.sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  def all_aggregate_fee_dues_by_branches(on_date, till_date = on_date, *at_branch_ids_ary)
    from_date, to_date = Constants::Time.ordered_dates(on_date, till_date)
    query = {:applied_on.gte => from_date, :applied_on.lte => to_date}
    query[:accounted_at] = at_branch_ids_ary if (at_branch_ids_ary and (not (at_branch_ids_ary.empty?)))
    query_results = FeeInstance.all(query)

    count = query_results.count
    sum_amount = MoneyManager.default_zero_money
    query_results.each do |x|
      sum_amount += x.effective_total_amount(on_date)
    end
    sum_money_amount = sum_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  def total_money_deposited_on_date_at_locations(on_date, *at_location_id)
    query = {:created_on => on_date, :at_location_id => at_location_id}
    all_money_deposits = MoneyDeposit.all(query)
    
    count = all_money_deposits.count
    sum_amount = all_money_deposits.aggregate(:amount.sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  def total_money_deposited_pending_verification_until_date_at_locations(on_date, *at_location_id)
    query = {:created_on.lte => on_date, :at_location_id => at_location_id, :verification_status => Constants::MoneyDepositVerificationStatus::PENDING_VERIFICATION}
    all_money_deposits = MoneyDeposit.all(query)

    count = all_money_deposits.count
    sum_amount = all_money_deposits.aggregate(:amount.sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  def total_money_deposited_verified_confirmed_on_date_at_locations(on_date, *at_location_id)
    query = {:created_on => on_date, :at_location_id => at_location_id, :verification_status => Constants::MoneyDepositVerificationStatus::VERIFIED_CONFIRMED}
    all_money_deposits = MoneyDeposit.all(query)

    count = all_money_deposits.count
    sum_amount = all_money_deposits.aggregate(:amount.sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  def total_money_deposited_verified_rejected_on_date_at_locations(on_date, *at_location_id)
    query = {:created_on => on_date, :at_location_id => at_location_id, :verification_status => Constants::MoneyDepositVerificationStatus::VERIFIED_REJECTED}
    all_money_deposits = MoneyDeposit.all(query)

    count = all_money_deposits.count
    sum_amount = all_money_deposits.aggregate(:amount.sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end
  
  def outstanding_loans_exceeding_days_past_due(days_past_due)
    outstanding_loans = all_outstanding_loans_on_date
    raise ArgumentError, "Days past due: #{days_past_due} must be a valid number of days" unless (days_past_due and (days_past_due > 0))
    outstanding_loans.select {|loan| (loan.days_past_due >= days_past_due)}
  end

  def loans_eligible_for_write_off(days_past_due = configuration_facade.days_past_due_eligible_for_writeoff)
    raise Errors::InvalidConfigurationError, "Days past due for write off has not been configured" unless days_past_due
    [days_past_due, loans_past_due(days_past_due)]
  end

  def loans_past_due(by_number_of_days = 1)
    outstanding_loans_exceeding_days_past_due(by_number_of_days)
  end

  def all_accrual_transactions_recorded_on_date(on_date)
    AccrualTransaction.all(:created_at.gt => on_date, :created_at.lt => (on_date + 1))
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

  #this is the main query method to find out aggregate of loans by branches for various statuses in a date range.
  def aggregate_loans_by_branches_for_status_during_a_date_range(for_status, on_date, till_date, *at_branch_ids_ary)
    from_date, to_date = Constants::Time.ordered_dates(on_date, till_date)
    loan_status, date_to_query, amount_to_sum = LoanLifeCycle::STATUSES_DATES_SUM_AMOUNTS[for_status]
    query = {:status => loan_status, date_to_query.gte => from_date, date_to_query.lte => to_date}
    query[:accounted_at_origin] = at_branch_ids_ary if (at_branch_ids_ary and (not (at_branch_ids_ary.empty?)))
    query_results = Lending.all(query)

    count = query_results.count
    sum_amount = query_results.aggregate(amount_to_sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
  end

  def aggregate_loans_by_branches_and_lending_products_for_status_on_date(for_status, on_date, lending_product_list, *at_branch_ids_ary)
    loan_status, date_to_query, amount_to_sum = LoanLifeCycle::STATUSES_DATES_SUM_AMOUNTS[for_status]
    query = {:status => loan_status, date_to_query => on_date, :lending_product_id => lending_product_list}
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

  #this method is to find out total loan allocation receipts at locations in a specified date range.
  def total_loan_allocation_receipts_at_locations_for_date_range(on_date, till_date, performed_or_accounted_choice, *at_location_ids_ary)
    total_loan_allocation_receipts_grouped_by_location = {}
    property_sym = TRANSACTION_LOCATIONS[performed_or_accounted_choice]
    at_location_ids_ary.each { |at_location_id|
      all_loan_receipts_at_location = LoanReceipt.all(:effective_on.gte => on_date, :effective_on.lte => till_date, property_sym => at_location_id)
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

  #main query to get outstanding loan_balances at locations for a date range.
  def all_outstanding_loans_balances_at_locations_for_date_range(on_date, till_date, accounted_or_administered_choice, *at_location_ids_ary)
    location_ids_array = *at_location_ids_ary.to_a
    all_loan_balances_grouped_by_location = {}
    all_loans_grouped_by_location = all_outstanding_loan_ids_at_locations_for_date_range(on_date, till_date, accounted_or_administered_choice, *at_location_ids_ary)
    for date in on_date..till_date
      all_loans_grouped_by_location.each { |at_location_id, for_loan_ids_ary|
        all_loan_balances_grouped_by_location[at_location_id] = loan_balances_for_loan_ids_for_date_range(date, for_loan_ids_ary)
      }
    end
    all_loan_balances_grouped_by_location
  end

  #method to get outstanding loan_ids for date range
  def all_outstanding_loan_ids_at_locations_for_date_range(on_date, till_date, accounted_or_administered_choice, *at_location_ids_ary)
    location_ids_array = *at_location_ids_ary.to_a
    all_loan_ids_grouped_by_location = {}
    location_ids_array.each { |at_location_id|
      all_loans_at_location = []
      all_outstanding_loans_at_location = []
      case accounted_or_administered_choice
      when Constants::Loan::ACCOUNTED_AT then all_loans_at_location = LoanAdministration.get_loans_accounted_for_date_range(at_location_id, on_date, till_date)
      when Constants::Loan::ADMINISTERED_AT then all_loans_at_location = LoanAdministration.get_loans_administered_for_date_range(at_location_id, on_date, till_date)
      else raise ArgumentError, "Please specify whether loans accounted or loans administered are needed"
      end
      for date in on_date..till_date
        all_loans_at_location.each do |loan|
          next if loan.applied_on_date > date
          all_outstanding_loans_at_location.push(loan) if loan.is_outstanding_on_date?(date)
        end
      end
      all_loan_ids_grouped_by_location[at_location_id] = get_ids(all_outstanding_loans_at_location)
    }
    all_loan_ids_grouped_by_location
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

  def configuration_facade
    @configuration_facade ||= FacadeFactory.instance.get_other_facade(FacadeFactory::CONFIGURATION_FACADE, self)
  end

  def get_ids(collection)
    raise ArgumentError, "Collection does not appear to be enumerable" unless collection.is_a?(Enumerable)
    collection.collect {|element| element.id}
  end

end
