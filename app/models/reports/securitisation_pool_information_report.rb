class SecuritisationPoolInformationReport < Report
  attr_accessor :from_date, :to_date, :biz_location_branch

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Securitisation Pool Information Report from #{@from_date} to #{@to_date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch] and (not (params[:biz_location_branch].empty?))) ? params[:biz_location_branch] : all_branch_ids
    get_parameters(params, user)
  end

  def name
    "Securitisation Pool Information Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Securitisation Pool Information Report"
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

  def generate

    data = {}
    branches = @biz_location_branch.class == Array ? @biz_location_branch : [@biz_location_branch]
    lendings = LoanStatusChange.status_between_dates(LoanLifeCycle::DISBURSED_LOAN_STATUS, @from_date, @to_date).lending
    lendings = lendings.select{|lending| branches.include?(lending.accounted_at_origin)}
    lendings.each do |loan|
      member                    = loan.loan_borrower.counterparty
      if member.blank?
        member_id = member_state = member_address = reference1_type = reference2_type = reference1_id = reference2_id = caste = religion = ''
        member_name = 'Not Specified'
      else
        member_id       = member.id
        member_name     = member.name
        member_state    = member.state
        member_address  = member.address
        reference1_type = member.reference_type
        reference1_id   = member.reference
        reference2_type = member.reference2_type
        reference2_id   = member.reference2
        caste           = member.caste
        religion        = member.religion
      end
      loan_account_number        = loan.lan
      loan_purpose               = loan.loan_purpose
      loan_cycle                 = ''
      loan_roi                   = loan.lending_product.interest_rate
      loan_insurance             = loan.simple_insurance_policies.blank? ? MoneyManager.default_zero_money : Money.new(loan.simple_insurance_policies.aggregate(:insured_amount.sum).to_i, default_currency)
      loan_end_date              = loan.last_scheduled_date
      loan_first_payment_date    = loan.loan_receipts.blank? ? loan.scheduled_first_repayment_date : loan.loan_receipts.first.effective_on
      fee_receipts               = FeeReceipt.all_paid_loan_fee_receipts(loan.id).map(&:fee_money_amount)
      fee_collected              = fee_receipts.blank? ? MoneyManager.default_zero_money : fee_receipts.sum
      installment_amount         = loan.scheduled_total_due(loan.scheduled_first_repayment_date)
      installment_frequency      = loan.lending_product.repayment_frequency
      installment_number         = loan.lending_product.tenure
      loan_disbursed_date        = loan.disbursal_date
      loan_disbursed_amount      = loan.to_money[:disbursed_amount]
      loan_outstanding_principal = loan.actual_principal_outstanding
      loan_outstanding_interest  = loan.actual_interest_outstanding
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

      data[loan.id] = {:member_name => member_name, :member_id => member_id,:member_address => member_address, :member_state => member_state,
        :center_name => center_name, :center_id => center_id, :loan_account_number => loan_account_number,
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
        :date_week => date_week, :principal_week => principal_week, :interest_week => interest_week }
    end
    data
  end

end
