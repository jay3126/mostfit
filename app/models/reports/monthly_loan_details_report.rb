class MonthlyLoanDetailsReport < Report
  attr_accessor :from_date, :to_date, :funding_line_id

  validates_with_method :funding_line_id, :funding_line_not_selected

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 30
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Monthly Loan Details Report from #{@from_date} to #{@to_date}"
    @user = user
    get_parameters(params, user)
  end

  def name
    "Monthly Loan Details Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Monthly Loan Details Report"
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
    loan_ids = FundingLineAddition.all(:funding_line_id => @funding_line_id).aggregate(:lending_id)
    loan_ids.each do |l|
      loan = Lending.get(l)
      member = loan.loan_borrower.counterparty
      if member.blank?
        member_id = member_state = member_address = reference1_type = reference2_type = reference1_id = reference2_id = caste = religion = 'Not Available'
        member_name = guarantor_name = occupation = gender = pincode = psl_category = village_slum = city = district = 'Not Available'
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
        caste           = member.caste.humanize
        religion        = member.religion.humanize
        guarantor_name  = member.guarantor_name.humanize
        occupation      = member.occupation.blank? ? 'Not Specified' : member.occupation.name.humanize
        gender          = (member and member.gender) ? member.gender.humanize : "Not Specified"
        pincode         = member.pincode
        psl_category    = member.psl_sub_category.blank? ? 'Not Specified' : member.psl_sub_category.name.humanize
        village_slum    = 'Not Specified'
        city            = 'Not Specified'
        district        = 'Not Specified'
      end

      loan_product_name          = loan.lending_product.name
      tenor_in_week              = loan.tenure
      disbursement_mode          = loan.disbursement_mode
      loan_start_date            = loan.is_outstanding? ? loan.disbursal_date : 'Not Specified'
      loan_status                = loan.status.humanize
      loan_account_number        = loan.lan
      loan_purpose               = loan.loan_purpose
      loan_cycle                 = loan.cycle_number
      loan_tenure                = loan.lending_product.tenure
      loan_roi                   = loan.lending_product.interest_rate
      loan_insurance             = loan.simple_insurance_policies.blank? ? MoneyManager.default_zero_money : Money.new(loan.simple_insurance_policies.aggregate(:insured_amount.sum).to_i, default_currency)
      loan_end_date              = loan.last_scheduled_date
      loan_first_payment_date    = loan.loan_receipts.blank? ? loan.scheduled_first_repayment_date : loan.loan_receipts.first.effective_on
      fee_receipts               = FeeReceipt.all_paid_loan_fee_receipts(loan.id).map(&:fee_money_amount)
      fee_collected              = fee_receipts.blank? ? MoneyManager.default_zero_money : fee_receipts.sum
      installment_amount         = loan.scheduled_total_due(loan.scheduled_first_repayment_date)
      installment_frequency      = loan.lending_product.repayment_frequency
      installment_number         = loan.lending_product.tenure
      loan_disbursed_date        = loan.disbursal_date.blank? ? 'Not Disbursed' : loan.disbursal_date
      loan_disbursed_amount      = loan.is_outstanding? ? loan.to_money[:disbursed_amount] : MoneyManager.default_zero_money
      loan_outstanding_principal = loan.actual_principal_outstanding(@to_date)
      loan_outstanding_interest  = loan.actual_interest_outstanding(@to_date)
      total_interest_due_at_org  = MoneyManager.default_zero_money
      demand_completed_weeks     = MoneyManager.default_zero_money
      date_week                  = ''
      principal_week             = MoneyManager.default_zero_money
      interest_week              = MoneyManager.default_zero_money
      center                     = loan.administered_at_origin_location
      center_id                  = center ? center.id : "Not Specified"
      center_name                = center ? center.name : "Not Specified"
      branch                     = loan.accounted_at_origin_location
      branch_name                = branch ? branch.name : "Not Specified"
      branch_id                  = branch ? branch.id : "Not Specified"
      loan_installment           = get_reporting_facade(@user).number_of_installments_per_loan(loan.id)
      overdue_amount             = get_reporting_facade(@user).overdue_amounts(loan.id, @to_date)
      overdue_principal          = overdue_amount[:principal_overdue_amount]
      overdue_interest           = overdue_amount[:interest_overdue_amount]
      installment_remaining      = loan_installment[:installments_remaining]
      weeks_since_disbursal      = ''
      weeks_remaining            = ''
      installments_paid          = loan_tenure-installment_remaining
      overdue_installment        = ''
      overdue_amount             = overdue_principal + overdue_interest
      days_overdue               = loan.is_outstanding? ? loan.days_past_due : 0
      payment_scheme             = 'Not Specified'
      security_deposit           = 'Not Specified'
      land_holding               = 'Not Specified'
      land_holding_in_acres      = 'Not Specified'
      days_since_disbursal       = loan.is_outstanding? ? (loan.disbursal_date..Date.today).to_a.size : 'Not Disbursed'
      days_remaining             = loan.is_outstanding? ? (Date.today..loan_end_date).to_a.size : 'Not Disbursed'
      ro_name                    = managed_by_staff(center.id, Date.today)
      status_date                = loan.loan_status_changes(:to_status => LoanLifeCycle::REPAID_LOAN_STATUS).first
      loan_closure_date          = status_date.blank? ? 'Not Forclosure' : status_date.effective_on
      source_of_fund_id          = NewFundingLine.get(FundingLineAddition.first(:lending_id => loan.id).funding_line_id).name
      meeting_address            = center.biz_location_address

      data[loan.id] = {:member_name => member_name, :member_id => member_id,:member_address => member_address, :member_state => member_state,
        :guarantor_name => guarantor_name, :occupation => occupation, :gender => gender, :pincode => pincode, :psl_category => psl_category,
        :village_slum => village_slum, :city => city, :district => district, :loan_product_name => loan_product_name, :tenor_in_week => tenor_in_week,
        :center_name => center_name, :center_id => center_id, :loan_account_number => loan_account_number, :phone_number => phone_number,
        :branch_name => branch_name, :branch_id => branch_id,
        :reference1_type => reference1_type, :reference1_id => reference1_id,
        :reference2_type => reference2_type, :reference2_id => reference2_id,
        :caste => caste, :religion => religion, :loan_purpose => loan_purpose,
        :loan_cycle => loan_cycle, :loan_roi => loan_roi, :loan_insurance => loan_insurance,
        :loan_end_date => loan_end_date, :first_payment_date => loan_first_payment_date,
        :fee_collected => fee_collected, :installment_amount => installment_amount,
        :installment_frequency => installment_frequency, :installment_number => installment_number,
        :loan_disbursed_date => loan_disbursed_date, :loan_disbursed_amount => loan_disbursed_amount,
        :loan_outstanding_principal => loan_outstanding_principal, :loan_outstanding_interest => loan_outstanding_interest,
        :total_interest_due_at_org => total_interest_due_at_org, :demand_completed_weeks => demand_completed_weeks,
        :date_week => date_week, :principal_week => principal_week, :interest_week => interest_week,
        :overdue_principal => overdue_principal, :overdue_interest => overdue_interest,
        :disbursement_mode => disbursement_mode, :loan_start_date => loan_start_date, :loan_status =>loan_status,
        :weeks_since_disbural => weeks_since_disbursal, :weeks_remaining => weeks_remaining, :installment_paid => installments_paid,
        :overdue_installment => overdue_installment, :days_overdue => days_overdue, :payment_scheme => payment_scheme, :security_deposit => security_deposit,
        :land_holding => land_holding, :land_holding_in_acres => land_holding_in_acres, :days_since_disbursal => days_since_disbursal,
        :days_remaining => days_remaining, :ro_name => ro_name, :loan_closure_date => loan_closure_date, :source_of_fund_id => source_of_fund_id, :meeting_address => meeting_address
      }

    end
    data
  end

  def funding_line_not_selected
    return [false, "Please select Funding Line"] if self.respond_to?(:funding_line_id) and not self.funding_line_id
    return true
  end
end
