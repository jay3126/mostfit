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

  #this method will return the number of installments remaining for a loan.
  def number_of_installments_per_loan(loan_id)
    result = {}
    loan = Lending.get(loan_id)
    if loan.loan_receipts.blank?
      installments_remaining = loan.tenure
      installments_paid_till_date = 0
    else
      last_payment_date = loan.loan_receipts.aggregate(:effective_on.max)
      installments = loan.loan_base_schedule.base_schedule_line_items(:on_date.lte => last_payment_date, :installment.gt => 0)
      installments_remaining = loan.tenure - installments.count
      installments_paid_till_date = installments.count
    end
    result = {:installments_remaining => installments_remaining, :installments_paid_till_date => installments_paid_till_date}
  end

  #this method will return due collected and due collectable per location(Branch) on a date.
  def total_schedule_collected_and_collectable_per_center_on_date(at_location_id, on_date = Date.today)
    loan_ids = LoanAdministration.get_loan_ids_administered_by_sql(at_location_id, on_date-1, false, 'disbursed_loan_status')
    schedule_loans_on_date = Lending.all(:id => loan_ids, 'loan_base_schedule.base_schedule_line_items.on_date' => on_date)
    loan_schedules = schedule_loans_on_date.blank? ? [] : BaseScheduleLineItem.all(:on_date => on_date, 'loan_base_schedule.lending_id' => schedule_loans_on_date.map(&:id))
    principal_schedule_amt = loan_schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_schedules.map(&:scheduled_principal_due).sum.to_i)
    interest_schedule_amt = loan_schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_schedules.map(&:scheduled_interest_due).sum.to_i)
    total_scheduled = principal_schedule_amt + interest_schedule_amt
 
    loan_receipts = schedule_loans_on_date.blank? ? [] : LoanReceipt.all(:lending_id => schedule_loans_on_date.map(&:id), :effective_on => on_date, 'payment_transaction.payment_towards' => [PAYMENT_TOWARDS_LOAN_REPAYMENT,PAYMENT_TOWARDS_LOAN_ADVANCE_ADJUSTMENT])
    loan_amts = LoanReceipt.add_up(loan_receipts)
    principal_received = loan_amts[:principal_received]
    interest_received = loan_amts[:interest_received]
    total_received = principal_received + interest_received
    managed_by_staff = LocationManagement.staff_managing_location(at_location_id, on_date)
    staff_name = managed_by_staff.blank? ? 'Not Managed' : StaffMember.get(managed_by_staff.manager_staff_id).name
    
    {:managed_by_staff => staff_name, :scheduled_principal => principal_schedule_amt, :scheduled_interest => interest_schedule_amt, :scheduled_total => total_scheduled, :principal_received => principal_received, :interest_received => interest_received, :total_received => total_received}
  end

  #this method will return due collected and due collectable per location(Branch) on a date.
  def total_dues_collected_and_collectable_per_location_on_date(at_location_id, on_date = Date.today)
    result = {}
    loan_ids = []
    loans_on_date = LoanAdministration.get_loan_ids_group_vise_accounted_by_sql(at_location_id, on_date)
    loans_before_date = LoanAdministration.get_loan_ids_group_vise_accounted_by_sql(at_location_id, on_date-1)

    disbursed_loans_on_date = loans_on_date[:disbursed_loan_status]
    preclose_loans_on_date = loans_on_date[:preclosed_loan_status]
    disbursed_loans = loans_before_date[:disbursed_loan_status]
    write_off_loans = loans_on_date[:written_off_loan_status] & loans_before_date[:written_off_loan_status]

    loan_schedule_items =  disbursed_loans.blank? ? [] : BaseScheduleLineItem.all('loan_base_schedule.lending_id' => disbursed_loans, :on_date => on_date)
    schedule_loans = loan_schedule_items.blank? ? [] : loan_schedule_items.loan_base_schedule.map(&:lending_id)
    loan_schedule_amt = loan_schedule_items.blank? ? [] : loan_schedule_items.aggregate(:scheduled_principal_due.sum, :scheduled_interest_due.sum) rescue []
    non_schedule_loans = disbursed_loans - schedule_loans
    loan_receipts_before_on_date = disbursed_loans.blank? ? [] : LoanReceipt.all(:lending_id => disbursed_loans, :effective_on.lt => on_date).aggregate(:principal_received.sum, :interest_received.sum, :advance_received.sum, :advance_adjusted.sum) rescue []
    preclose_loan_receipt_on_date = preclose_loans_on_date.blank? ? [] : LoanReceipt.all(:is_advance_adjusted => false, :lending_id => preclose_loans_on_date, 'payment_transaction.payment_towards' => :payment_towards_loan_preclosure, :effective_on => on_date).aggregate(:principal_received.sum, :interest_received.sum) rescue []

    advance_available = loan_receipts_before_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts_before_on_date[2].to_i-loan_receipts_before_on_date[3].to_i)
    future_loans = non_schedule_loans.blank? ? [] : Lending.all(:id => non_schedule_loans, 'loan_base_schedule.base_schedule_line_items.on_date'.to_sym.gte => on_date).aggregate(:id) rescue []
    past_loans = non_schedule_loans.blank? ? [] : non_schedule_loans - future_loans
    unless past_loans.blank?
      Lending.all(:id => past_loans, :fields => [:id, :repayment_frequency]).group_by{|l| l.repayment_frequency}.each do |frequency, loans|
        if frequency == :weekly || frequency == :biweekly
          loan_ids << repository(:default).adapter.query("select l.id from lendings l where DAYNAME(l.scheduled_first_repayment_date) = '#{on_date.weekday.to_s}' and l.id IN (#{loans.map(&:id).join(',')})")
        elsif frequency == :monthly
          loan_ids << repository(:default).adapter.query("select l.id from lendings l where DAYOFMONTH(l.scheduled_first_repayment_date) = '#{on_date.day}' and l.id IN (#{loans.map(&:id).join(',')})")
        end
      end
    end
    schedule_loans = (schedule_loans + loan_ids.flatten).uniq
    if schedule_loans.blank?
      schedule_principal_due = MoneyManager.default_zero_money
      schedule_interest_due = MoneyManager.default_zero_money
      overdue_total_ftd = MoneyManager.default_zero_money
      schedule_advance_balance = MoneyManager.default_zero_money
    else
      schedule_principal_due = MoneyManager.get_money_instance_least_terms(loan_schedule_amt[0].to_i)
      schedule_interest_due = MoneyManager.get_money_instance_least_terms(loan_schedule_amt[1].to_i)
      schedule_before_on_date = BaseScheduleLineItem.all('loan_base_schedule.lending_id' => schedule_loans, :on_date.lt => on_date).aggregate(:scheduled_principal_due.sum, :scheduled_interest_due.sum) rescue []
      schedule_principal_before_on_date = schedule_before_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(schedule_before_on_date[0].to_i)
      schedule_interest_before_on_date = schedule_before_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(schedule_before_on_date[1].to_i)
      loan_receipts_before_on_date = LoanReceipt.all(:is_advance_adjusted => false, :lending_id => schedule_loans, :effective_on.lt => on_date)
      loan_receipts_amt = LoanReceipt.add_up(loan_receipts_before_on_date) 
      overdue_principal_ftd = schedule_principal_before_on_date > loan_receipts_amt[:principal_received] ? schedule_principal_before_on_date - loan_receipts_amt[:principal_received] : MoneyManager.default_zero_money
      overdue_interest_ftd = schedule_interest_before_on_date > loan_receipts_amt[:interest_received] ? schedule_interest_before_on_date - loan_receipts_amt[:interest_received] : MoneyManager.default_zero_money
      schedule_advance_balance = loan_receipts_amt[:advance_received] > loan_receipts_amt[:advance_adjusted] ? loan_receipts_amt[:advance_received] - loan_receipts_amt[:advance_adjusted] : MoneyManager.default_zero_money
      overdue_total_ftd = overdue_principal_ftd + overdue_interest_ftd
      overdue_total_ftd = schedule_advance_balance < overdue_total_ftd ? schedule_advance_balance - overdue_total_ftd : MoneyManager.default_zero_money
    end
    
    non_schedule_loans = disbursed_loans - schedule_loans
    non_schedule = BaseScheduleLineItem.all('loan_base_schedule.lending_id' => non_schedule_loans, :on_date.lt => on_date).aggregate(:scheduled_principal_due.sum, :scheduled_interest_due.sum) rescue []
    non_schedule_principal = non_schedule.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(non_schedule[0].to_i)
    non_schedule_interest= non_schedule.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(non_schedule[1].to_i)
    non_schedule_loan_receipts = non_schedule.blank? ? '' : LoanReceipt.all(:is_advance_adjusted => false, :lending_id => non_schedule_loans, :effective_on.lt => on_date)
    non_schedule_loan_receipts_amt = LoanReceipt.add_up(non_schedule_loan_receipts)
    non_schedule_overdue_principal = non_schedule_principal > non_schedule_loan_receipts_amt[:principal_received] ? non_schedule_principal - non_schedule_loan_receipts_amt[:principal_received] : MoneyManager.default_zero_money
    non_schedule_overdue_interest = non_schedule_interest > non_schedule_loan_receipts_amt[:interest_received] ? non_schedule_interest - non_schedule_loan_receipts_amt[:interest_received] : MoneyManager.default_zero_money
    non_schedule_overdue_total = non_schedule_overdue_principal + non_schedule_overdue_interest
    schedule_total = schedule_principal_due + schedule_interest_due

    disbursed_loan_on_date = Lending.all(:id => disbursed_loans_on_date, :disbursal_date => on_date, :fields => [:id, :disbursed_amount])
    preclose_loan_on_date = Lending.all(:id => preclose_loans_on_date, :preclosed_on_date => on_date, :fields => [:id, :disbursed_amount])
    insurance_policies_on_date = disbursed_loan_on_date.blank? ? [] : disbursed_loan_on_date.simple_insurance_policies
    loan_fee_instance = disbursed_loan_on_date.blank? && preclose_loan_on_date.blank? ? [] : FeeInstance.all(:fee_applied_on_type => :fee_on_loan, :fee_applied_on_type_id => disbursed_loan_on_date.map(&:id)+preclose_loan_on_date.map(&:id))
    insurance_fee_instance = insurance_policies_on_date.blank? ? [] : FeeInstance.all(:fee_applied_on_type => :fee_on_insurance, :fee_applied_on_type_id => insurance_policies_on_date.map(&:id))
    
    loan_fee_amount = loan_fee_instance.blank? ? MoneyManager.default_zero_money : loan_fee_instance.map(&:total_money_amount).sum
    insurance_fee_amount = insurance_fee_instance.blank? ? MoneyManager.default_zero_money : insurance_fee_instance.map(&:total_money_amount).sum
    
    total_fee_colleatable_on_date = loan_fee_amount + insurance_fee_amount
    
    loan_fee_receipts_on_date = FeeReceipt.sum(:fee_amount, :fee_amount.not => nil, :fee_applied_on_type => :fee_on_loan, :accounted_at => at_location_id, :effective_on => on_date) rescue []
    loan_fee_receipt_amount = loan_fee_receipts_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_fee_receipts_on_date.to_i)

    other_loan_fee_receipts_on_date = FeeReceipt.sum(:fee_amount, :fee_amount.not => nil, :fee_applied_on_type => :fee_on_insurance, :accounted_at => at_location_id, :effective_on => on_date) rescue []
    other_fee_receipt_amount = other_loan_fee_receipts_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(other_loan_fee_receipts_on_date.to_i)

    schedule_loan_receipts = schedule_loans.blank? ? [] : LoanReceipt.all(:is_advance_adjusted => false, :lending_id => schedule_loans, :effective_on => on_date, 'payment_transaction.payment_towards' => [PAYMENT_TOWARDS_LOAN_REPAYMENT])
    schedule_loan_amts =  LoanReceipt.add_up(schedule_loan_receipts)
    schedule_principal_received = schedule_loan_amts[:principal_received]
    schedule_interest_received = schedule_loan_amts[:interest_received]
    schedule_advance_received = schedule_loan_amts[:advance_received]
    schedule_total_received = schedule_principal_received + schedule_interest_received

    overdue_loan_receipts = non_schedule_loans.blank? ? [] : LoanReceipt.all(:is_advance_adjusted => false, :lending_id => non_schedule_loans, :effective_on => on_date, 'payment_transaction.payment_towards' => [PAYMENT_TOWARDS_LOAN_REPAYMENT])
    overdue_loan_amts =  LoanReceipt.add_up(overdue_loan_receipts)
    overdue_principal_received = overdue_loan_amts[:principal_received]
    overdue_interest_received = overdue_loan_amts[:interest_received]
    non_schedule_advance_received = overdue_loan_amts[:advance_received]
    overdue_total_received = overdue_principal_received + overdue_interest_received

    write_off_amts = write_off_loans.blank? ? [] : LoanReceipt.sum(:loan_recovery, :is_advance_adjusted => false, :accounted_at => at_location_id, :effective_on => on_date)
    recovery_received = write_off_amts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(write_off_amts.to_i)

    preclose_principal_received_on_date = preclose_loan_receipt_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(preclose_loan_receipt_on_date[0].to_i)
    preclose_interest_received_on_date = preclose_loan_receipt_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(preclose_loan_receipt_on_date[1].to_i)
    total_preclose_received_on_date = preclose_principal_received_on_date + preclose_interest_received_on_date

    total_advance_received = non_schedule_advance_received + schedule_advance_received
    {:scheduled_principal => schedule_principal_due, :scheduled_interest => schedule_interest_due, :scheduled_total => schedule_total,
      :scheduled_advance_balance => schedule_advance_balance, :advance_amount_exist => advance_available, :overdue_ftd => overdue_total_ftd, :overdue_amt => non_schedule_overdue_total,
      :scheduled_principal_collected => schedule_principal_received, :scheduled_interest_collected => schedule_interest_received, :scheduled_total_collected => schedule_total_received,
      :advance_received => total_advance_received, :overdue_received => overdue_total_received, :recovery_collected => recovery_received,
      :preclosure_pricipal => preclose_principal_received_on_date, :priclosure_interest => preclose_interest_received_on_date, :total_preclosure => total_preclose_received_on_date,
      :fee_colleatable => total_fee_colleatable_on_date, :fee_colleated => loan_fee_receipt_amount, :insurance_fee_collected => other_fee_receipt_amount
    }
  end

  #this function will give back the list of staff_members per location.
  def staff_members_per_location_on_date(at_location_id, on_date)
    params = {:at_location_id => at_location_id, :effective_on.lte => on_date}
    staffs = StaffPosting.all(params)
    staffs
  end

  #this function will give back the list of location which is managed by staff.
  def locations_managed_by_staffs_on_date(staff_id, to_date, from_date = nil)
    new_members = []
    new_centers = []
    exist_centers = []
    exist_members = []
    locations = LocationManagement.locations_managed_by_staff_by_sql(staff_id, to_date)
    locations.group_by{|g| g.location_level_id}.each do |location_level_id, biz_locations|
      l_level = LocationLevel.get(location_level_id)
      if l_level.level == 0
        centers= biz_locations
      elsif l_level.level == 1
        centers = []
        biz_locations.each do |l|
          centers << LocationLink.get_children_by_sql(l, to_date)
        end
      end
      l_locations = centers.blank? ? [] : centers.flatten.uniq
      if from_date.blank?
        n_centers = l_locations.select{|s| s.center_disbursal_date <= to_date}
      else
        n_centers = l_locations.select{|s| s.center_disbursal_date >= from_date && s.center_disbursal_date <= to_date}
      end
      e_centers = l_locations - n_centers

      new_centers << n_centers
      exist_centers << e_centers
      new_members << ClientAdministration.get_client_ids_administered_by_sql(n_centers.map(&:id), to_date) unless n_centers.blank?
      exist_members << ClientAdministration.get_client_ids_administered_by_sql(e_centers.map(&:id), to_date) unless e_centers.blank?

    end
    new_centers = new_centers.blank? ? [] : new_centers.flatten.uniq.compact
    exist_centers = exist_centers.blank? ? [] : exist_centers.flatten.uniq.compact
    new_members = new_members.blank? ? [] : new_members.flatten.uniq.compact
    exist_members = exist_members.blank? ? [] : exist_members.flatten.uniq.compact
    
    {:new_locations_count => new_centers.count, :new_location_ids => new_centers.map(&:id), :new_members_count => new_members.count, :exist_locations_count => exist_centers.count, :exist_location_ids => exist_centers.map(&:id), :exist_members_count => exist_members.count}
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

  def all_outstanding_loans_on_date(on_date = Date.today, accounted_at = nil, administered_at = nil)
    search = {}
    search[:accounted_at_origin] = accounted_at unless accounted_at.blank?
    search[:administered_at_origin] = administered_at unless administered_at.blank?
    Lending.all(search).select{|loan| loan.is_outstanding_on_date?(on_date)}
  end
  
  def all_outstanding_loan_IDs_on_date(on_date = Date.today)
    get_ids(all_outstanding_loans_on_date(on_date))
  end

  def sum_all_loans_balances_at_accounted_locations_on_date(on_date, *at_location_ids_ary)
    loan_amounts = {}
    at_location_ids_ary.each do |location_id|
      loans                 = LoanAdministration.get_loan_ids_group_vise_accounted_by_sql(location_id, on_date)
      loans_ids             = loans.blank? ? [] : loans.values.flatten
      preclose_loan_ids     = loans[LoanLifeCycle::PRECLOSED_LOAN_STATUS]
      disbursed_loan_ids    = loans[LoanLifeCycle::DISBURSED_LOAN_STATUS]
      loan_disbursement     = disbursed_loan_ids.blank? ? [] : repository(:default).adapter.query(" SELECT SUM(total_loan_disbursed) as disbursed_principal, SUM(total_interest_applicable) as disbursed_interest FROM loan_base_schedules where lending_id IN (#{disbursed_loan_ids.join(',')})").first
      till_on_loan_receipts = disbursed_loan_ids.blank? ? [] : repository(:default).adapter.query(" SELECT SUM(principal_received) as principal, SUM(interest_received) as interest, SUM(advance_received) as advance, SUM(advance_adjusted) as advance_adjustment, SUM(loan_recovery) as recovery FROM loan_receipts where lending_id IN (#{disbursed_loan_ids.join(',')}) AND effective_on <= '#{on_date.strftime('%Y-%m-%d')}'").first
      loan_receipts         = disbursed_loan_ids.blank? ? [] : repository(:default).adapter.query(" SELECT SUM(principal_received) as principal, SUM(interest_received) as interest, SUM(advance_received) as advance, SUM(advance_adjusted) as advance_adjustment, SUM(loan_recovery) as recovery FROM loan_receipts where lending_id IN (#{disbursed_loan_ids.join(',')}) AND effective_on = '#{on_date.strftime('%Y-%m-%d')}'").first
      loan_preclose         = preclose_loan_ids.blank? ? [] : repository(:default).adapter.query(" SELECT SUM(principal_received) as principal, SUM(interest_received) as interest FROM loan_receipts where lending_id IN (#{preclose_loan_ids.join(',')}) AND effective_on = #{on_date}").first
      fee_amt               = FeeReceipt.all(:accounted_at => location_id, :effective_on => on_date).aggregate(:fee_amount.sum) rescue []
      scheduled_amounts     = loans_ids.blank? ? [] : BaseScheduleLineItem.all('loan_base_schedule.lending.id' => loans_ids, :on_date.lte => on_date).aggregate(:scheduled_principal_due.sum, :scheduled_interest_due.sum) rescue []
      loan_amounts[location_id]                            = {}
      loan_amounts[location_id]['disbursed_principal_amt'] = loan_disbursement.blank? || loan_disbursement.disbursed_principal.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_disbursement.disbursed_principal.to_i)
      loan_amounts[location_id]['disbursed_interest_amt']  = loan_disbursement.blank? || loan_disbursement.disbursed_interest.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_disbursement.disbursed_interest.to_i)
      loan_amounts[location_id]['principal_amt']           = loan_receipts.blank? || loan_receipts.principal.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts.principal.to_i)
      loan_amounts[location_id]['interest_amt']            = loan_receipts.blank? || loan_receipts.interest.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts.interest.to_i)
      loan_amounts[location_id]['advance_amt']             = loan_receipts.blank? || loan_receipts.advance.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts.advance.to_i)
      loan_amounts[location_id]['advance_adjustment_amt']  = loan_receipts.blank? || loan_receipts.advance_adjustment.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts.advance_adjustment.to_i)
      loan_amounts[location_id]['recovery_amt']            = loan_receipts.blank? || loan_receipts.recovery.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts.recovery.to_i)
      loan_amounts[location_id]['fee_amt']                 = fee_amt.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(fee_amt.to_i)

      loan_amounts[location_id]['preclose_principal_amt']  = loan_preclose.blank? || loan_preclose.principal.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_preclose.principal)
      loan_amounts[location_id]['preclose_interest_amt']   = loan_preclose.blank? || loan_preclose.interest.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_preclose.interest)
      loan_amounts[location_id]['scheduled_principal_amt'] = scheduled_amounts[0].blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(scheduled_amounts[0].to_i)
      loan_amounts[location_id]['scheduled_interest_amt']  = scheduled_amounts[1].blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(scheduled_amounts[1].to_i)
      
      loan_amounts[location_id]['total_principal_amt']       = till_on_loan_receipts.blank? || till_on_loan_receipts.principal.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(till_on_loan_receipts.principal.to_i)
      loan_amounts[location_id]['total_interest_amt']        = till_on_loan_receipts.blank? || till_on_loan_receipts.interest.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(till_on_loan_receipts.interest.to_i)
      loan_amounts[location_id]['total_advance_amt']         = till_on_loan_receipts.blank? || till_on_loan_receipts.advance.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(till_on_loan_receipts.advance.to_i)
      loan_amounts[location_id]['total_advance_adjust_amt']  = till_on_loan_receipts.blank? || till_on_loan_receipts.advance_adjustment.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(till_on_loan_receipts.advance_adjustment.to_i)
      loan_amounts[location_id]['total_advance_balance_amt'] = loan_amounts[location_id]['total_advance_amt'] - loan_amounts[location_id]['total_advance_adjust_amt']
    end
    loan_amounts
  end

  #this function is for Delinquency report.
  def sum_all_loans_balances_at_accounted_locations_on_date_for_delinquency_report(on_date, *at_location_ids_ary)
    loan_amounts = {}
    at_location_ids_ary.each do |location_id|
      loans                 = LoanAdministration.get_loan_ids_group_vise_accounted_by_sql(location_id, on_date)
      loans_ids             = loans.blank? ? [] : loans.values.flatten
      disbursed_loan_ids    = loans[LoanLifeCycle::DISBURSED_LOAN_STATUS]
      loan_disbursement     = disbursed_loan_ids.blank? ? [] : repository(:default).adapter.query(" SELECT SUM(total_loan_disbursed) as disbursed_principal, SUM(total_interest_applicable) as disbursed_interest FROM loan_base_schedules where lending_id IN (#{disbursed_loan_ids.join(',')})").first
      till_on_loan_receipts = disbursed_loan_ids.blank? ? [] : repository(:default).adapter.query(" SELECT SUM(principal_received) as principal, SUM(interest_received) as interest, SUM(advance_received) as advance, SUM(advance_adjusted) as advance_adjustment, SUM(loan_recovery) as recovery FROM loan_receipts where lending_id IN (#{disbursed_loan_ids.join(',')}) AND effective_on <= '#{on_date.strftime('%Y-%m-%d')}'").first
      loan_receipts         = disbursed_loan_ids.blank? ? [] : repository(:default).adapter.query(" SELECT SUM(principal_received) as principal, SUM(interest_received) as interest, SUM(advance_received) as advance, SUM(advance_adjusted) as advance_adjustment, SUM(loan_recovery) as recovery FROM loan_receipts where lending_id IN (#{disbursed_loan_ids.join(',')}) AND effective_on = '#{on_date.strftime('%Y-%m-%d')}'").first
      scheduled_amounts     = loans_ids.blank? ? [] : BaseScheduleLineItem.all('loan_base_schedule.lending.id' => loans_ids, :on_date.lte => on_date).aggregate(:scheduled_principal_due.sum, :scheduled_interest_due.sum) rescue []
      loan_amounts[location_id]                            = {}
      loan_amounts[location_id]['disbursed_principal_amt'] = loan_disbursement.blank? || loan_disbursement.disbursed_principal.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_disbursement.disbursed_principal.to_i)
      loan_amounts[location_id]['principal_amt']           = loan_receipts.blank? || loan_receipts.principal.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts.principal.to_i)
      loan_amounts[location_id]['interest_amt']            = loan_receipts.blank? || loan_receipts.interest.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts.interest.to_i)
      loan_amounts[location_id]['scheduled_principal_amt'] = scheduled_amounts[0].blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(scheduled_amounts[0].to_i)
      loan_amounts[location_id]['scheduled_interest_amt']  = scheduled_amounts[1].blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(scheduled_amounts[1].to_i)
      loan_amounts[location_id]['total_principal_amt']       = till_on_loan_receipts.blank? || till_on_loan_receipts.principal.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(till_on_loan_receipts.principal.to_i)
    end
    loan_amounts
  end

  def sum_all_loans_balances_at_accounted_locations_for_date_range(on_date, till_date, *at_location_ids_ary)
    loan_amounts = {}
    at_location_ids_ary.each do |location_id|
      loans                 = LoanAdministration.get_loan_ids_group_vise_accounted_for_date_range_by_sql(location_id, on_date, till_date)
      loans_ids             = loans.blank? ? [] : loans.values.flatten
      preclose_loan_ids     = loans[LoanLifeCycle::PRECLOSED_LOAN_STATUS]
      disbursed_loan_ids    = loans[LoanLifeCycle::DISBURSED_LOAN_STATUS]
      loan_disbursement     = disbursed_loan_ids.blank? ? [] : repository(:default).adapter.query(" SELECT SUM(total_loan_disbursed) as disbursed_principal, SUM(total_interest_applicable) as disbursed_interest FROM loan_base_schedules where lending_id IN (#{disbursed_loan_ids.join(',')})").first
      till_on_loan_receipts = disbursed_loan_ids.blank? ? [] : repository(:default).adapter.query(" SELECT SUM(principal_received) as principal, SUM(interest_received) as interest, SUM(advance_received) as advance, SUM(advance_adjusted) as advance_adjustment, SUM(loan_recovery) as recovery FROM loan_receipts where lending_id IN (#{disbursed_loan_ids.join(',')}) AND effective_on <= '#{till_date.strftime('%Y-%m-%d')}'").first
      loan_receipts         = loans_ids.blank? ? [] : LoanReceipt.all(:lending_id => loans_ids, :effective_on.gte => on_date, :effective_on.lte => till_date).aggregate(:principal_received.sum, :interest_received.sum, :advance_received.sum, :advance_adjusted.sum, :loan_recovery.sum) rescue []
      loan_preclose         = preclose_loan_ids.blank? ? [] : repository(:default).adapter.query(" SELECT SUM(principal_received) as principal, SUM(interest_received) as interest FROM loan_receipts where lending_id IN (#{preclose_loan_ids.join(',')}) AND effective_on >= '#{on_date.strftime('%Y-%m-%d')}' AND effective_on <= '#{till_date.strftime('%Y-%m-%d')}'").first
      fee_amt               = FeeReceipt.all(:accounted_at => location_id, :effective_on.gte => on_date, :effective_on.lte => till_date).aggregate(:fee_amount.sum)  rescue []
      scheduled_amounts     = loans_ids.blank? ? [] : BaseScheduleLineItem.all('loan_base_schedule.lending.id' => loans_ids, :on_date.gte => on_date, :on_date.lte => till_date).aggregate(:scheduled_principal_due.sum, :scheduled_interest_due.sum) rescue []
      loan_amounts[location_id]                            = {}
      
      loan_amounts[location_id]['disbursed_principal_amt'] = loan_disbursement.blank? || loan_disbursement.disbursed_principal.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_disbursement.disbursed_principal.to_i)
      loan_amounts[location_id]['disbursed_interest_amt']  = loan_disbursement.blank? || loan_disbursement.disbursed_interest.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_disbursement.disbursed_interest.to_i)
      loan_amounts[location_id]['principal_amt']           = loan_receipts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts[0].to_i)
      loan_amounts[location_id]['interest_amt']            = loan_receipts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts[1].to_i)
      loan_amounts[location_id]['advance_amt']             = loan_receipts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts[2].to_i)
      loan_amounts[location_id]['advance_adjustment_amt']  = loan_receipts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts[3].to_i)
      loan_amounts[location_id]['recovery_amt']            = loan_receipts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts[4].to_i)
      loan_amounts[location_id]['fee_amt']                 = fee_amt.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(fee_amt.to_i)

      loan_amounts[location_id]['preclose_principal_amt']  = loan_preclose.blank? || loan_preclose.principal.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_preclose.principal)
      loan_amounts[location_id]['preclose_interest_amt']   = loan_preclose.blank? || loan_preclose.interest.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_preclose.interest)
      loan_amounts[location_id]['scheduled_principal_amt'] = scheduled_amounts[0].blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(scheduled_amounts[0].to_i)
      loan_amounts[location_id]['scheduled_interest_amt']  = scheduled_amounts[1].blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(scheduled_amounts[1].to_i)

      loan_amounts[location_id]['total_principal_amt']       = till_on_loan_receipts.blank? || till_on_loan_receipts.principal.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(till_on_loan_receipts.principal.to_i)
      loan_amounts[location_id]['total_interest_amt']        = till_on_loan_receipts.blank? || till_on_loan_receipts.interest.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(till_on_loan_receipts.interest.to_i)
      loan_amounts[location_id]['total_advance_amt']         = till_on_loan_receipts.blank? || till_on_loan_receipts.advance.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(till_on_loan_receipts.advance.to_i)
      loan_amounts[location_id]['total_advance_adjust_amt']  = till_on_loan_receipts.blank? || till_on_loan_receipts.advance_adjustment.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(till_on_loan_receipts.advance_adjustment.to_i)
      loan_amounts[location_id]['total_advance_balance_amt'] = loan_amounts[location_id]['total_advance_amt'] - loan_amounts[location_id]['total_advance_adjust_amt']
    end
    loan_amounts
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

  #this function will give the total amount outstanding for loans disbursed till date.
  def sum_all_outstanding_loans
    MoneyManager.get_money_instance_least_terms((PaymentTransaction.all(:payment_towards => :payment_towards_loan_disbursement, :effective_on.lte => Date.today).sum(:amount).to_i - PaymentTransaction.all(:payment_towards => :payment_towards_loan_repayment, :effective_on.lte => Date.today).sum(:amount).to_i))
  end

  #this function will give the total loan amount per branch for a date range.
  def sum_all_loan_amounts_per_center_for_a_date_range(from_date, to_date, for_location_id)
    result = {}
    loan_amount = MoneyManager.default_zero_money
    loan_ids = Lending.all(:disbursal_date.gte => from_date, :disbursal_date.lte => to_date, :administered_at_origin => for_location_id).aggregate(:id)
    loan_ids.each do |l|
      loan = Lending.get(l)
      next unless loan.is_outstanding?
      loan_amount += MoneyManager.get_money_instance(Money.new(loan.applied_amount.to_i, :INR).to_s)
    end
    result = {:total_loan_amount => loan_amount}
  end

  #this function will give the total amount outstanding for loans disbursed till date.
  def sum_all_outstanding_and_overdues_loans_per_branch_on_date(on_date, *at_location_ids_ary)
    loans = []
    default_currency = MoneyManager.get_default_currency
    loans = LoanAdministration.get_loans_accounted_by_sql(at_location_ids_ary.flatten, on_date, false,'disbursed_loan_status') unless at_location_ids_ary.flatten.blank?
    loan_ids = loans.blank? ? [] : loans.map(&:id)
    actual_outstanding_amount = scheduled_outstanding_amount = overdue_amounts = MoneyManager.default_zero_money
    loan_schedules = BaseScheduleLineItem.all('loan_base_schedule.lending.id' => loan_ids, :on_date.lte => on_date)
    scheduled_amounts = loan_schedules.blank? ? [0,0] : loan_schedules.aggregate(:scheduled_principal_due.sum, :scheduled_interest_due.sum)
    scheduled_principal = scheduled_amounts[0] <= 0 ? MoneyManager.default_zero_money : Money.new(scheduled_amounts[0].to_i, default_currency)
    scheduled_interest  = scheduled_amounts[1] <= 0 ? MoneyManager.default_zero_money : Money.new(scheduled_amounts[1].to_i, default_currency)
    scheduled_total  = scheduled_principal + scheduled_interest

    received_till_date = LoanReceipt.all(:lending_id => loan_ids, :effective_on.lte => on_date)
    received_amounts = received_till_date.blank? ? [0,0,0,0,0] : received_till_date.aggregate(:principal_received.sum,:interest_received.sum, :advance_received.sum, :advance_adjusted.sum, :loan_recovery.sum)
    received_principal = received_amounts[0] <= 0 ? MoneyManager.default_zero_money : Money.new(received_amounts[0].to_i, default_currency)
    received_interest = received_amounts[1] <= 0 ? MoneyManager.default_zero_money : Money.new(received_amounts[1].to_i, default_currency)
    received_total = received_principal + received_interest

    disbursed_till_date = loans.blank? ? [0,0] : LoanBaseSchedule.all(:lending_id => loans.map(&:id)).aggregate(:total_loan_disbursed.sum, :total_interest_applicable.sum)
    principal_disbursed = disbursed_till_date[0] <= 0 ? MoneyManager.default_zero_money : Money.new(disbursed_till_date[0].to_i, default_currency)
    interest_disbursed = disbursed_till_date[1] <= 0 ? MoneyManager.default_zero_money : Money.new(disbursed_till_date[1].to_i, default_currency)
    total_disbursed = principal_disbursed + interest_disbursed
    actual_outstanding_amount = total_disbursed - received_total
    scheduled_outstanding_amount = total_disbursed - scheduled_total
    overdue_amounts = received_principal < scheduled_principal ? scheduled_principal-received_principal : MoneyManager.default_zero_money

    {:actual_outstanding_amount => actual_outstanding_amount, :scheduled_outstanding_amount => scheduled_outstanding_amount, :overdue_amounts => overdue_amounts}
  end

  #this function will give the total amount outstanding for loans disbursed till date.
  def sum_all_outstanding_and_overdues_loans_location_centers_on_date(on_date, *at_location_ids_ary)
    loans = []
    default_currency = MoneyManager.get_default_currency
    loan_ids = LoanAdministration.get_loan_ids_administered_by_sql(at_location_ids_ary.flatten, on_date, false,'disbursed_loan_status') unless at_location_ids_ary.flatten.blank?

    actual_outstanding_amount = scheduled_outstanding_amount = overdue_amounts = MoneyManager.default_zero_money
    scheduled_amounts = loan_ids.blank? ? [] : BaseScheduleLineItem.all('loan_base_schedule.lending_id' => loan_ids, :on_date.lte => on_date).aggregate(:scheduled_principal_due.sum, :scheduled_interest_due.sum) rescue []
    scheduled_principal = scheduled_amounts.blank? ? MoneyManager.default_zero_money : Money.new(scheduled_amounts[0].to_i, default_currency)
    scheduled_interest  = scheduled_amounts.blank? ? MoneyManager.default_zero_money : Money.new(scheduled_amounts[1].to_i, default_currency)

    received_amounts = loan_ids.blank? ? [] :  LoanReceipt.all(:lending_id => loan_ids, :effective_on.lte => on_date, 'payment_transaction.payment_towards' => PAYMENT_TOWARD_FOR_REPAYMENT).aggregate(:principal_received.sum,:interest_received.sum, :advance_received.sum, :advance_adjusted.sum, :loan_recovery.sum) rescue []
    received_principal = received_amounts.blank? ? MoneyManager.default_zero_money : Money.new(received_amounts[0].to_i, default_currency)
    received_interest = received_amounts.blank? ? MoneyManager.default_zero_money : Money.new(received_amounts[1].to_i, default_currency)

    disbursed_till_date = loan_ids.blank? ? [] : LoanBaseSchedule.all(:lending_id => loan_ids).aggregate(:total_loan_disbursed.sum, :total_interest_applicable.sum)
    principal_disbursed = disbursed_till_date.blank? ? MoneyManager.default_zero_money : Money.new(disbursed_till_date[0].to_i, default_currency)
    interest_disbursed = disbursed_till_date.blank? ? MoneyManager.default_zero_money : Money.new(disbursed_till_date[1].to_i, default_currency)
    actual_principal_outstanding = principal_disbursed > received_principal ? principal_disbursed - received_principal : MoneyManager.default_zero_money
    actual_interest_outstanding = interest_disbursed > received_interest ? interest_disbursed - received_interest : MoneyManager.default_zero_money
    actual_outstanding_amount = actual_principal_outstanding + actual_interest_outstanding
    scheduled_outstanding_principal = principal_disbursed > scheduled_principal ? principal_disbursed - scheduled_principal : MoneyManager.default_zero_money
    scheduled_interest_outstanding = interest_disbursed > scheduled_interest ? interest_disbursed - scheduled_interest : MoneyManager.default_zero_money
    scheduled_outstanding_amount = scheduled_outstanding_principal + scheduled_interest_outstanding
    overdue_principal = received_principal < scheduled_principal ? scheduled_principal-received_principal : MoneyManager.default_zero_money
    overdue_interest = received_interest < scheduled_interest ? scheduled_interest-received_interest : MoneyManager.default_zero_money
    total_overdue = overdue_principal + overdue_interest
    {:actual_principal_outstanding_amount => actual_principal_outstanding, :actual_interest_outstanding_amount => actual_interest_outstanding, :actual_outstanding_amount => actual_outstanding_amount,
      :scheduled_principal_outstanding_amount => scheduled_outstanding_principal, :scheduled_interest_outstanding_amount => scheduled_interest_outstanding, :scheduled_outstanding_amount => scheduled_outstanding_amount,
      :overdue_principal_amounts => overdue_principal, :overdue_interest_amounts => overdue_interest, :overdue_amounts => total_overdue}
  end

  def overdue_loans_for_location(location_id, on_date)
    loan_ids = LoanAdministration.get_loan_ids_accounted_by_sql(location_id, on_date, false, 'disbursed_loan_status')
    loan_due_statuses = LoanDueStatus.all(:lending_id => loan_ids, :on_date => on_date).aggregate(:lending_id) rescue []

    non_due_status_loans = loan_ids.blank? ? [] : loan_ids - loan_due_statuses
    non_due_status_loans.each{|loan_id| LoanDueStatus.generate_loan_due_status(loan_id, on_date)}
    loan_ids.blank? ? [] : repository(:default).adapter.query("Select a.lending_id from loan_due_statuses a where a.due_status = 4 AND a.lending_id IN (#{loan_ids.join(',')}) AND (a.lending_id, a.id) = (select b.lending_id, b.id from loan_due_statuses b where b.lending_id = a.lending_id AND b.on_date = '#{on_date.strftime('%Y-%m-%d')}' ORDER BY b.created_at desc LIMIT 1);")
  end

  def overdue_loans_for_location_center_wise(on_date, *location_id)
    location_id.flatten.blank? ? [] : repository(:default).adapter.query("select lendings.id from lendings inner join loan_base_schedules on loan_base_schedules.lending_id = lendings.id where lendings.administered_at_origin IN (#{location_id.flatten.join(',')}) and (select sum(principal_received+interest_received) from loan_receipts where loan_receipts.lending_id = lendings.id and effective_on <= '#{on_date.strftime("%Y-%m-%d")}' and deleted_at is null) < (select sum(scheduled_principal_due+scheduled_interest_due) from base_schedule_line_items where base_schedule_line_items.loan_base_schedule_id = loan_base_schedules.id and loan_base_schedules.lending_id = lendings.id and base_schedule_line_items.on_date <= '#{on_date.strftime("%Y-%m-%d")}');")
  end

  def get_overdue_status_for_branch_on_date(on_date, *location_id)
    if location_id.flatten.blank?
      loan_ids = Lending.total_loans_on_date('disbursed_loan_status', on_date)
    else
      loan_ids = LoanAdministration.get_loan_ids_accounted_by_sql(location_id.flatten, on_date, false, 'disbursed_loan_status') unless location_id.flatten.blank?
    end
    loan_due_statuses = LoanDueStatus.all(:lending_id => loan_ids, :on_date => on_date).aggregate(:lending_id) rescue []

    non_due_status_loans = loan_ids.blank? ? [] : loan_ids - loan_due_statuses
    non_due_status_loans.each{|loan_id| LoanDueStatus.generate_loan_due_status(loan_id, on_date)}
    loan_ids.blank? ? [] : repository(:default).adapter.query("Select * from loan_due_statuses a where a.due_status = 4 AND a.lending_id IN (#{loan_ids.join(',')}) AND (a.lending_id, a.id) = (select b.lending_id, b.id from loan_due_statuses b where b.lending_id = a.lending_id AND b.on_date = '#{on_date.strftime('%Y-%m-%d')}' ORDER BY b.created_at desc LIMIT 1);")
  end

  def get_loan_due_status_for_branch_on_date(on_date, *location_id)
    if location_id.flatten.blank?
      loan_ids = Lending.total_loans_on_date('disbursed_loan_status', on_date)
    else
      loan_ids = LoanAdministration.get_loan_ids_accounted_by_sql(location_id.flatten, on_date, false, 'disbursed_loan_status') unless location_id.flatten.blank?
    end
    loan_due_statuses = LoanDueStatus.all(:lending_id => loan_ids, :on_date => on_date).aggregate(:lending_id) rescue []

    non_due_status_loans = loan_ids.blank? ? [] : loan_ids - loan_due_statuses
    non_due_status_loans.each{|loan_id| LoanDueStatus.generate_loan_due_status(loan_id, on_date)}
    loan_ids.blank? ? [] : repository(:default).adapter.query("Select * from loan_due_statuses a where a.lending_id IN (#{loan_ids.join(',')}) AND (a.lending_id, a.id) = (select b.lending_id, b.id from loan_due_statuses b where b.lending_id = a.lending_id AND b.on_date = '#{on_date.strftime('%Y-%m-%d')}' ORDER BY b.created_at desc LIMIT 1);")
  end

  def get_loan_due_status_for_sof_on_date(on_date, *funding_line)
    return {} if funding_line.flatten.blank?
    data = {}
    fundings = NewFundingLine.all(:id => funding_line.flatten)
    fundings.each do |funding|

      disbursed_ids = funding.funding_line_additions(:created_on.lte => on_date).lending('loan_status_changes.from_status'.to_sym.not => :disbursed_loan_status, 'loan_status_changes.effective_on'.to_sym.lte => on_date).aggregate(:id) rescue []
      loan_due_statuses = LoanDueStatus.all(:lending_id => disbursed_ids, :on_date => on_date).aggregate(:lending_id) rescue []
      non_due_status_loans = disbursed_ids.blank? ? [] : disbursed_ids - loan_due_statuses
      non_due_status_loans.each{|loan_id| LoanDueStatus.generate_loan_due_status(loan_id, on_date)}
      data[funding.name] = disbursed_ids.blank? ? [] : repository(:default).adapter.query("Select * from loan_due_statuses a where a.lending_id IN (#{disbursed_ids.join(',')}) AND (a.lending_id, a.id) = (select b.lending_id, b.id from loan_due_statuses b where b.lending_id = a.lending_id AND b.on_date = '#{on_date.strftime('%Y-%m-%d')}' ORDER BY b.id desc LIMIT 1);")
    end
    data
  end

  #this method will return back the overdue values (principal and interest) on date.
  def overdue_amounts(loan_id, on_date)
    result = {}
    loan = Lending.get(loan_id)
    if loan.is_outstanding? && loan.days_past_due_on_date(on_date) > 0

      if loan.scheduled_principal_outstanding(on_date) > loan.actual_principal_outstanding(on_date)
        principal_overdue_amount = (loan.scheduled_principal_outstanding(on_date) - loan.actual_principal_outstanding(on_date))
      else
        principal_overdue_amount = (loan.actual_principal_outstanding(on_date) - loan.scheduled_principal_outstanding(on_date))
      end

      if loan.scheduled_interest_outstanding(on_date) > loan.actual_interest_outstanding(on_date)
        interest_overdue_amount = (loan.scheduled_interest_outstanding(on_date) - loan.actual_interest_outstanding(on_date))
      else
        interest_overdue_amount = (loan.actual_interest_outstanding(on_date) - loan.scheduled_interest_outstanding(on_date))
      end
    else
      principal_overdue_amount = interest_overdue_amount = MoneyManager.default_zero_money
    end
    result = {:principal_overdue_amount => principal_overdue_amount, :interest_overdue_amount => interest_overdue_amount}
  end

  #this method return back the outstanding values including overdue amounts.
  def sum_outstanding_amounts_including_overdues(loan_id, on_date)
    result = {}
    loan = Lending.get(loan_id)
    if loan.is_outstanding?
      outstanding_principal_amount = loan.scheduled_principal_outstanding(on_date)
      outstanding_interest_amount = loan.scheduled_interest_outstanding(on_date)

      if loan.scheduled_principal_outstanding(on_date) > loan.actual_principal_outstanding(on_date)
        principal_overdue_amount = (loan.scheduled_principal_outstanding(on_date) - loan.actual_principal_outstanding(on_date))
      else
        principal_overdue_amount = (loan.actual_principal_outstanding(on_date) - loan.scheduled_principal_outstanding(on_date))
      end

      if loan.scheduled_interest_outstanding(on_date) > loan.actual_interest_outstanding(on_date)
        interest_overdue_amount = (loan.scheduled_interest_outstanding(on_date) - loan.actual_interest_outstanding(on_date))
      else
        interest_overdue_amount = (loan.actual_interest_outstanding(on_date) - loan.scheduled_interest_outstanding(on_date))
      end

      principal_outstanding_including_overdues = outstanding_principal_amount + principal_overdue_amount
      interest_outstanding_including_overdues = outstanding_interest_amount + interest_overdue_amount
    else
      principal_outstanding_including_overdues = interest_outstanding_including_overdues = MoneyManager.default_zero_money
    end
    result = {:principal_outstanding_including_overdues => principal_outstanding_including_overdues, :interest_outstanding_including_overdues => interest_outstanding_including_overdues}
  end

  def overdue_amount_for_location(at_location_id, on_date = Date.today)
    biz_location = BizLocation.get at_location_id
    overdue_amount = MoneyManager.default_zero_money
    if biz_location.location_level.level == 0
      loans = LoanAdministration.get_loans_administered(at_location_id, on_date).compact
    else
      loans = LoanAdministration.get_loans_accounted(at_location_id, on_date).compact
    end
    loans.each{|loan| overdue_amount +=loan.overdue_amount(on_date)}
    overdue_amount
  end

  #this functions gives the repayments details till date.
  def sum_all_repayments
    result = {}
    params = {:effective_on.lt => Date.today, :loan_recovery => 0.0, "lending.status.not" => :repaid_loan_status}
    principal_received = LoanReceipt.all(params).aggregate(:principal_received.sum)
    interest_received = LoanReceipt.all(params).aggregate(:interest_received.sum)
    advance_received = LoanReceipt.all(params).aggregate(:advance_received.sum)
    advance_adjusted = LoanReceipt.all(params).aggregate(:advance_adjusted.sum)
    total_received = (principal_received || 0) + (interest_received || 0)
    principal_money_amount_received = Money.new(principal_received.to_i, :INR).to_s
    interest_money_amount_received = Money.new(interest_received.to_i, :INR).to_s
    advance_money_amount_received = Money.new(advance_received.to_i, :INR).to_s
    advance_money_amount_adjusted = Money.new(advance_adjusted.to_i, :INR).to_s
    total_money_amount_received = Money.new(total_received.to_i, :INR).to_s
    result = {:principal_received => principal_money_amount_received, :interest_received => interest_money_amount_received, :advance_received => advance_money_amount_received, :advance_adjusted => advance_money_amount_adjusted, :total_received => total_money_amount_received}
  end

  #this function gives the fee payments.
  def sum_all_fee_receipts
    params = {:effective_on.lt => Date.today}
    fee_receipt = FeeReceipt.all(params).aggregate(:fee_amount.sum)
    fee_money_amount_receipt = Money.new(fee_receipt.to_i, :INR).to_s
    result = {:fee_receipt => fee_money_amount_receipt}
  end

  #this function gives all the pre-closures and write-off's values.
  def sum_all_pre_closure_and_write_off_payments
    result = {}
    written_off_params = {:effective_on.lt => Date.today, "lending.status" => :written_off_loan_status}
    pre_closure_params = {:effective_on.lt => Date.today, "lending.status" => :repaid_loan_status}
    written_off_amount = LoanReceipt.all(written_off_params).aggregate(:loan_recovery.sum)
    principal_received = LoanReceipt.all(pre_closure_params).aggregate(:principal_received.sum)
    interest_received = LoanReceipt.all(pre_closure_params).aggregate(:interest_received.sum)
    pre_closure_amount = (principal_received || 0) + (interest_received || 0)
    written_off_money_amount = Money.new(written_off_amount.to_i, :INR).to_s
    pre_closure_money_amount = Money.new(pre_closure_amount.to_i, :INR).to_s
    result = {:written_off_amount => written_off_money_amount, :pre_closure_amount => pre_closure_money_amount}
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
    if loan_ids_array.is_a?(Fixnum)
      for_loan_id = loan_ids_array
      loan = Lending.get(for_loan_id)
      if on_date >= loan.disbursal_date
        due_status_record = LoanDueStatus.most_recent_status_record_on_date(for_loan_id, on_date)
        loan_balances_by_loan_id[for_loan_id] = due_status_record.to_money if due_status_record
      else
        loan_balances_by_loan_id[for_loan_id] = MoneyManager.default_zero_money
      end
    else
      loan_ids_array.each { |for_loan_id|
        loan = Lending.get(for_loan_id)
        if on_date >= loan.disbursal_date
          due_status_record = LoanDueStatus.most_recent_status_record_on_date(for_loan_id, on_date)
          loan_balances_by_loan_id[for_loan_id] = due_status_record.to_money if due_status_record
        else
          loan_balances_by_loan_id[for_loan_id] = MoneyManager.default_zero_money
        end
      }
    end
    loan_balances_by_loan_id
  end

  #this method id to find out loan_balances for loan_ids for a date range.
  def loan_balances_for_loan_ids_for_date_range(on_date, *for_loan_ids_ary)
    loan_ids_array = *for_loan_ids_ary.to_a
    loan_balances_by_loan_id = {}
    loan_ids_array1 = loan_ids_array.uniq
    if (loan_ids_array1 and (not loan_ids_array1.empty?))
      loan_ids_array1.each { |for_loan_id|
        loan = Lending.get(for_loan_id)
        if on_date >= loan.disbursal_date
          due_status_record = LoanDueStatus.most_recent_status_record_on_date(for_loan_id, on_date)
          loan_balances_by_loan_id[for_loan_id] = due_status_record.to_money if due_status_record
        else
          loan_balances_by_loan_id[for_loan_id] = MoneyManager.default_zero_money
        end
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

  #following function is to find out the fees due per loan.
  def all_fees_due_per_loan(loan_id, on_date)
    fee_amount = MoneyManager.default_zero_money
    loan = Lending.get(loan_id)
    unpaid_loan_fee_instances = loan.unpaid_loan_fees.map{|fi| fi.simple_fee_product_id}
    unpaid_loan_fee_instances.each do |ulfi|
      simple_fee_product = SimpleFeeProduct.get(ulfi)
      fee_amount += simple_fee_product.effective_total_amount(on_date)
    end
    fee_amount
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
  
  def outstanding_loans_exceeding_days_past_due(days_past_due, accounted_at = nil, administered_at = nil)
    outstanding_loans = all_outstanding_loans_on_date(Date.today, accounted_at, administered_at)
    raise ArgumentError, "Days past due: #{days_past_due} must be a valid number of days" unless (days_past_due and (days_past_due > 0))
    outstanding_loans.select {|loan| (loan.days_past_due >= days_past_due)}
  end

  def loans_eligible_for_write_off(days_past_due = configuration_facade.days_past_due_eligible_for_writeoff, accounted_at =nil,administered_at =nil)
    raise Errors::InvalidConfigurationError, "Days past due for write off has not been configured" unless days_past_due
    [days_past_due, loans_past_due(days_past_due, accounted_at, administered_at)]
  end

  def loans_past_due(by_number_of_days = 1, accounted_at = nil, administered_at = nil)
    outstanding_loans_exceeding_days_past_due(by_number_of_days, accounted_at, administered_at)
  end

  def all_accrual_transactions_recorded_on_date(on_date, loan_id = nil)
    search = {}
    search[:effective_on.lte] = on_date
    search[:accounting]       = false
    unless loan_id.blank?
      search[:on_product_type] = :lending
      search[:on_product_id] = loan_id
    end
    AccrualTransaction.all(search)
  end

  #this function gives back the total amount paid towards written-off status for loan.
  def aggregate_loans_by_branches_for_written_off_status_on_date(for_status, on_date, *at_branch_ids_ary)
    loan_status, date_to_query = LoanLifeCycle::STATUSES_DATES_FOR_WRITE_OFF[for_status]
    loan_query = {:status => loan_status, date_to_query => on_date}
    loan_query[:accounted_at_origin] = at_branch_ids_ary if (at_branch_ids_ary and (not (at_branch_ids_ary.empty?)))
    loan_ids = Lending.all(loan_query).aggregate(:id)

    query = {:effective_on => on_date, :lending_id => loan_ids}
    query_results = LoanReceipt.all(query)

    sum_amount = (query_results and (not query_results.empty?)) ? query_results.aggregate(:loan_recovery.sum) : 0
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:total_amount => sum_money_amount}
  end

  #this function gives back the total amount paid towards pre-closure status for loan.
  def aggregate_loans_by_branches_for_pre_closure_status_on_date(for_status, on_date, *at_branch_ids_ary)
    loan_status = LoanLifeCycle::STATUSES_DATES_FOR_PRE_CLOSURE[for_status]
    loan_query = {:status => loan_status}
    loan_query[:accounted_at_origin] = at_branch_ids_ary if (at_branch_ids_ary and (not (at_branch_ids_ary.empty?)))
    loan_ids = Lending.all(loan_query).aggregate(:id)

    status_change_query = {:to_status => loan_status, :lending_id => loan_ids, :effective_on => on_date}
    status_change_loan_ids = (LoanStatusChange.all(status_change_query) and (not LoanStatusChange.all(status_change_query).empty?)) ? LoanStatusChange.all(status_change_query).aggregate(:lending_id) : []

    query = {:effective_on => on_date, :lending_id => status_change_loan_ids}
    query_results = LoanReceipt.all(query)

    sum_principal_received = (query_results and (not query_results.empty?)) ? query_results.aggregate(:principal_received.sum) : 0
    sum_interest_received = (query_results and (not query_results.empty?)) ? query_results.aggregate(:interest_received.sum) : 0
    sum_principal_received_money_amount = sum_principal_received ? to_money_amount(sum_principal_received) : zero_money_amount
    sum_interest_received_money_amount = sum_interest_received ? to_money_amount(sum_interest_received) : zero_money_amount
    total_amount_received = sum_principal_received_money_amount + sum_interest_received_money_amount
    {:principal_received => sum_principal_received_money_amount, :interest_received => sum_interest_received_money_amount, :total_received => total_amount_received}
  end

  #this function gives loan amounts and count for various statuses.
  def aggregate_loans_for_status(for_status, on_date)
    loan_status, date_to_query, amount_to_sum = LoanLifeCycle::STATUSES_DATES_SUM_AMOUNTS[for_status]
    query = {:status => loan_status, date_to_query.lt => on_date}
    query_results = Lending.all(query)

    count = query_results.count
    sum_amount = query_results.aggregate(amount_to_sum)
    sum_money_amount = sum_amount ? to_money_amount(sum_amount) : zero_money_amount
    {:count => count, :total_amount => sum_money_amount}
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
      params = {:effective_on => on_date, property_sym => at_location_id, :loan_recovery => 0, :"lending.status.not" => :repaid_loan_status}
      all_loan_receipts_at_location = LoanReceipt.all(params)
      total_loan_allocation_receipts_grouped_by_location[at_location_id] = LoanReceipt.add_up(all_loan_receipts_at_location)
    }
    total_loan_allocation_receipts_grouped_by_location
  end

  #this method is to find out total loan allocation receipts at locations in a specified date range.
  def total_loan_allocation_receipts_at_locations_for_date_range(on_date, till_date, performed_or_accounted_choice, *at_location_ids_ary)
    total_loan_allocation_receipts_grouped_by_location = {}
    property_sym = TRANSACTION_LOCATIONS[performed_or_accounted_choice]
    at_location_ids_ary.each { |at_location_id|
      params = {:effective_on.gte => on_date, :effective_on.lte => till_date, property_sym => at_location_id, :loan_recovery => 0, :"lending.status.not" => :repaid_loan_status}
      all_loan_receipts_at_location = LoanReceipt.all(params)
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
