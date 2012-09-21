class SecuritisationLoanDetailsReport < Report
  attr_accessor :funding_line_id, :date

  validates_with_method :funding_line_id, :funding_line_not_selected

  def initialize(params, dates, user)
    @date = Date.parse(params[:date]) rescue Date.today
    @name = "Securitisation Loan Details Report on #{@date}"
    @user = user
    get_parameters(params, user)
  end

  def name
    "Securitisation Loan Details Report on #{@date}"
  end

  def self.name
    "Securitisation Loan Details Report"
  end

  def get_reporting_facade(user)
    @reporting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, user)
  end

  def get_location_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user)
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def managed_by_staff(location_id, on_date)
    location_facade = get_location_facade(@user)
    location_manage = location_facade.location_managed_by_staff(location_id, on_date)
    if location_manage.blank?
      'Not Managed'
    else
      staff_member = location_manage.manager_staff_member.name
    end
  end

  def generate

    data     = {}
    lendings = []
    loan_ids = FundingLineAddition.all(:funding_line_id => @funding_line_id).aggregate(:lending_id)
    loan_ids.each do |l|
      loan = Lending.get(l)
      member = loan.loan_borrower.counterparty
      if member.blank?
        member_id   = member_state = member_address = reference1_type = reference2_type = reference1_id = reference2_id = caste_name = religion_name = ''
        member_name = guarantor_name = occupation_name = gender_name = pincode = village = city = district = ''
      else
        member_id       = member.id
        member_name     = member.name.humanize
        member_state    = member.state.humanize
        member_address  = member.address
        phone_number    = member.telephone_number
        reference1_type = member.reference_type.humanize
        reference1_id   = member.reference
        reference2_type = member.reference2_type.humanize
        reference2_id   = member.reference2
        caste_name      = member.caste.humanize
        religion_name   = member.religion.humanize
        guarantor_name  = member.guarantor_name.humanize
        occupation_name = member.occupation.blank? ? 'Not Specified' : member.occupation.name.humanize
        gender_name     = member.gender.humanize
        pincode         = member.pincode
        village         = 'Not Specified'
        city            = 'Not Specified'
        district        = 'Not Specified'
      end

      loan_product_name                = loan.lending_product.name
      disbursement_mode                = 'Not Specified'
      loan_start_date                  = loan.is_outstanding? ? loan.disbursal_date : 'Not Disbursed'
      loan_status                      = loan.status.humanize
      loan_account_number              = loan.lan
      loan_purpose                     = loan.loan_purpose
      loan_cycle                       = loan.cycle_number
      loan_roi                         = loan.lending_product.interest_rate
      loan_insurance                   = loan.simple_insurance_policies.map(&:simple_insurance_produet.name).join(', ') rescue 'No Insurance'
      loan_matruity_date               = loan.last_scheduled_date
      loan_first_payment_date          = loan.loan_receipts.blank? ? loan.scheduled_first_repayment_date : loan.loan_receipts.first.effective_on
      installment_amount               = loan.scheduled_total_due(loan.scheduled_first_repayment_date)
      repay_frequency                  = loan.lending_product.repayment_frequency
      number_of_installment            = loan.lending_product.tenure
      installment_type                 = 'Not Specified'
      interest_type                    = 'Not Specified'
      prepay_penalty                   = MoneyManager.default_zero_money
      prepay_penalty_type              = 'Not Specified'
      penalty_on_overdue               = MoneyManager.default_zero_money
      overdue_penalty_type             = 'Not Specified'
      upfront_charges                  = MoneyManager.default_zero_money
      upfront_charges_type             = 'Not Specified'
      upfront_deposit_type             = 'Not Specified'
      upfront_refund_deposit           = MoneyManager.default_zero_money
      other_upfront_collection         = MoneyManager.default_zero_money
      other_upfront_collection_type    = 'Not Specified'
      collateral_security_type         = "Not Specified"
      collateral_value                 = MoneyManager.default_zero_money
      top_up_loan_product              = 'Not Specified'
      repayment_schedule_provided      = 'Not Specified'
      customer_type                    = 'Not Specified'
      ewi_amount                       = loan.scheduled_total_due(loan.scheduled_first_repayment_date)
      ewi_date                         = loan.scheduled_first_repayment_date
      number_of_repayments             = loan.loan_receipts.count
      amounts_info                     = loan.get_sum_scheduled_amounts_info_till_date(@date)
      principal_on_date                = loan.principal_received_till_date(@date)
      interest_on_date                 = loan.interest_received_till_date(@date)
      schedule_principal_due_till_date = amounts_info[:sum_of_scheduled_principal_due]
      schedule_interest_due_till_date  = amounts_info[:sum_of_scheduled_interest_due]
      overdue_amount                   = get_reporting_facade(@user).overdue_amounts(loan.id, @date)
      loan_overdue_principal           = overdue_amount[:principal_overdue_amount]
      loan_overdue_interest            = overdue_amount[:interest_overdue_amount]
      loan_total_overdue               = loan_overdue_principal + loan_overdue_interest
      number_of_days_overdues          = loan.is_outstanding? ? loan.days_past_due_on_date(@date) : 0
      days_since_disbursal             = loan.is_outstanding? ? (loan.disbursal_date..Date.today).to_a.size : 'Not Disbursed'
      days_remaining                   = loan.is_outstanding? ? (Date.today..loan_matruity_date).to_a.size : 'Not Disbursed'
      weeks_since_disbursal            = (days_since_disbursal/7).to_i
      weeks_remaining                  = (days_remaining/7).to_i
      loan_frequence_days              = days_of_repayment_frequency(repay_frequency)
      loan_overdue_installments        = number_of_days_overdues > 0 ? (number_of_days_overdues/loan_frequence_days + 1).to_i : 0
      loan_disbursed_date              = loan.disbursal_date.blank? ? 'Not Disbursed' : loan.disbursal_date
      loan_disbursed_amount            = loan.is_outstanding? ? loan.to_money[:disbursed_amount] : MoneyManager.default_zero_money
      loan_total_principal_due         = schedule_principal_due_till_date < principal_on_date ? MoneyManager.default_zero_money : (schedule_principal_due_till_date - principal_on_date)
      loan_total_interest_due          = schedule_interest_due_till_date < interest_on_date ? MoneyManager.default_zero_money : (schedule_interest_due_till_date - interest_on_date)
      loan_total_due                   = loan_total_principal_due + loan_total_interest_due
      center                           = loan.administered_at_origin_location
      center_id                        = center ? center.id : "Not Specified"
      center_name                      = center ? center.name : "Not Specified"
      branch                           = loan.accounted_at_origin_location
      branch_name                      = branch ? branch.name : "Not Specified"
      branch_id                        = branch ? branch.id : "Not Specified"
      all_parent_locations             = LocationLink.all_parents(branch, Date.today)
      state_name                       = all_parent_locations.select{|l| l.location_level.downcase == 'state'}.name rescue 'Not Specified'
      district_name                    = all_parent_locations.select{|l| l.location_level.downcase == 'district'}.name rescue 'Not Specified'

      data[loan.id] = {:member_name => member_name, :member_id => member_id,:member_address => member_address, :member_state => member_state,
        :guarantor_name => guarantor_name, :occupation_name => occupation_name, :gender_name => gender_name, :pincode => pincode,
        :village => village, :city => city, :member_district => district, :loan_product_name => loan_product_name, :customer_type => customer_type,
        :center_name => center_name, :center_id => center_id, :loan_account_number => loan_account_number, :phone_number => phone_number,
        :branch_name => branch_name, :branch_id => branch_id, :reference1_type => reference1_type, :reference1_id => reference1_id,
        :reference2_type => reference2_type, :reference2_id => reference2_id, :caste_name => caste_name, :religion_name => religion_name, :loan_purpose => loan_purpose,
        :loan_cycle => loan_cycle, :loan_roi => loan_roi, :loan_insurance => loan_insurance, :loan_matruity_date => loan_matruity_date, :first_payment_date => loan_first_payment_date,
        :installment_amount => installment_amount, :repay_frequency => repay_frequency, :number_of_installment => number_of_installment, :loan_overdue_installments => loan_overdue_installments,
        :loan_disbursed_date => loan_disbursed_date, :loan_disbursed_amount => loan_disbursed_amount, :loan_total_principal_due => loan_total_principal_due, :loan_total_interest_due => loan_total_interest_due,
        :loan_overdue_principal => loan_overdue_principal, :disbursement_mode => disbursement_mode, :loan_start_date => loan_start_date, :loan_status =>loan_status,
        :state_name => state_name, :district_name => district_name, :installment_type => installment_type, :interest_type => interest_type, :prepay_penalty => prepay_penalty ,:prepay_penalty_type => prepay_penalty_type,
        :penalty_on_overdue => penalty_on_overdue, :overdue_penalty_type => overdue_penalty_type, :upfront_charges => upfront_charges, :upfront_charges_type => upfront_charges_type,
        :upfront_refund_deposit => upfront_refund_deposit, :upfront_deposit_type => upfront_deposit_type, :other_upfront_collection => other_upfront_collection, :other_upfront_collection_type => other_upfront_collection_type,
        :collateral_security_type => collateral_security_type, :collateral_value => collateral_value, :top_up_loan_product => top_up_loan_product, :repayment_schedule_provided => repayment_schedule_provided,
        :ewi_amount => ewi_amount, :ewi_date => ewi_date, :number_of_repayments => number_of_repayments, :loan_principal_due => principal_on_date, :loan_interest => interest_on_date, :loan_total_due => loan_total_due,
        :loan_total_overdue => loan_total_overdue, :loan_overdue_interest => loan_overdue_interest, :number_of_days_overdues => number_of_days_overdues, :weeks_since_disbursal => weeks_since_disbursal, :weeks_remaining => weeks_remaining
      }
    end
    data
  end

  def days_of_repayment_frequency(frequency)
    case frequency.to_s
    when 'monthly'
      30
    when 'biweekly'
      14
    when 'weekly'
      7
    when 'daily'
      1
    end
  end

  def funding_line_not_selected
    return [false, "Please select Funding Line"] if self.respond_to?(:funding_line_id) and not self.funding_line_id
    return true
  end

end
