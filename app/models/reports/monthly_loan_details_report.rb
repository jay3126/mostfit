class MonthlyLoanDetailsReport < Report
  attr_accessor :date, :loan_active_status, :page

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @status = params.blank? || params[:loan_active_status].blank? ? '' : params[:loan_active_status]
    @name = "Monthly Loan Details Report from #{@date}"
    @user = user
    @page = params.blank? || params[:page].blank? ? 1 : params[:page]
    @limit = 100
    get_parameters(params, user)
  end

  def name
    "Monthly Loan Details Report from #{@date}"
  end

  def self.name
    "Monthly Loan Details Report"
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def managed_by_staff(location_id, on_date)
    location_facade =  FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, @user)
    location_manage = location_facade.location_managed_by_staff(location_id, on_date)
    return location_manage.blank? ? 'Not Managed' : location_manage.manager_staff_member.name
  end

  def get_reporting_facade(user)
    @reporting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, user)
  end

  def generate
    data     = {}
    if @status == 'Live Loans'
      @loan_ids = Lending.total_loans_on_date('disbursed_loan_status', @date).to_a.paginate(:page => @page, :per_page => @limit)
    elsif @status == 'Close/Preclose Loans'
      preclose_loans = Lending.total_loans_on_date('preclosed_loan_status', @date)
      repaid_loans = Lending.total_loans_on_date('repaid_loan_status', @date)
      @loan_ids = (preclose_loans+repaid_loans).to_a.paginate(:page => @page, :per_page => @limit)
    else
      @loan_ids = []
    end
    loans = @loan_ids.blank? ? [] : Lending.all(:id => @loan_ids)
    data[:loan_ids] = @loan_ids
    data[:loans] = {}
    loan_borrowers = loans.blank? ? [] : loans.loan_borrower.aggregate(:counterparty_id)
    clients = loan_borrowers.blank? ? [] : Client.all(:id => loan_borrowers)
    loans.each do |loan|
      member = clients.select{|s| s.id == loan.loan_borrower.counterparty_id}.first

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
        gender          = (member && member.gender) ? member.gender.humanize : "Not Specified"
        pincode         = member.pincode
        psl_category    = member.psl_sub_category.blank? ? 'Not Specified' : member.psl_sub_category.name.humanize
        village_slum    = 'Not Specified'
        city            = 'Not Specified'
        district        = 'Not Specified'
      end
      loan_product               = loan.lending_product
      loan_product_name          = loan_product.name
      tenor_in_week              = loan.tenure
      disbursement_mode          = loan.disbursement_mode
      loan_start_date            = loan.is_outstanding? ? loan.disbursal_date : 'Not Specified'
      loan_status                = loan.status.humanize
      loan_account_number        = loan.lan
      loan_purpose               = loan.loan_purpose
      loan_cycle                 = loan.cycle_number
      loan_roi                   = loan_product.interest_rate
#      loan_insurance             = loan.simple_insurance_policies.blank? ? MoneyManager.default_zero_money : Money.new(loan.simple_insurance_policies.aggregate(:insured_amount.sum).to_i, default_currency)
      loan_insurance             = MoneyManager.default_zero_money

      loan_first_payment_date    = loan.loan_receipts.blank? ? loan.scheduled_first_repayment_date : loan.loan_receipts.first.effective_on
#      fee_receipts               = FeeReceipt.all_paid_loan_fee_receipts(loan.id).map(&:fee_money_amount)
#      fee_collected              = fee_receipts.blank? ? MoneyManager.default_zero_money : fee_receipts.sum
      fee_collected              = MoneyManager.default_zero_money
      installment_amount         = loan.scheduled_total_due(loan.scheduled_first_repayment_date)
      installment_frequency      = loan_product.repayment_frequency
      installment_number         = loan_product.tenure
      loan_disbursed_date        = loan.disbursal_date.blank? ? 'Not Disbursed' : loan.disbursal_date
      loan_disbursed_amount      = loan.to_money[:disbursed_amount]
      loan_interest_amount       = loan.loan_base_schedule.to_money[:total_interest_applicable]

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
      all_receipts               = loan.loan_receipts
      all_receipts_amt           = LoanReceipt.add_up(all_receipts)
      all_principal_received     = all_receipts_amt[:principal_received]
      all_interest_received      = all_receipts_amt[:interest_received]
      all_schedules              = BaseScheduleLineItem.all('loan_base_schedule.lending_id' => loan.id, :installment.not => 0)
      schedules                  = all_schedules.select{|s| s.on_date <= @date}
      schedule_principal         = schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(schedules.map(&:scheduled_principal_due).sum.to_i)
      schedule_interest          = schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(schedules.map(&:scheduled_interest_due).sum.to_i)
      loan_receipts              = all_receipts.select{|r| r.effective_on <= @date}
      loan_amt                   = LoanReceipt.add_up(loan_receipts)
      loan_first_payment_date    = all_receipts.blank? ? loan.scheduled_first_repayment_date : loan.loan_receipts.first.effective_on
      last_payment_date          = ''
      overdue_installment        = 0
      
      loan_receipts.map(&:effective_on).sort.each do |date|
        l_schedule = all_schedules.select{|s| s.on_date <= date}
        l_receipt = all_receipts.select{|r| r.effective_on <= date}
        l_receipt_amt = LoanReceipt.add_up(l_receipt)
        s_principal         = l_schedule.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(l_schedule.map(&:scheduled_principal_due).sum.to_i)
        s_interest          = l_schedule.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(l_schedule.map(&:scheduled_interest_due).sum.to_i)
        p_received         = l_receipt_amt[:principal_received]
        i_received          = l_receipt_amt[:interest_received]
        if s_principal <= p_received && s_interest <= i_received
          last_payment_date = date
          break
        end
      end
      principal_received         = loan_amt[:principal_received]
      interest_received          = loan_amt[:interest_received]
      overdue_principal          = schedule_principal > principal_received ? schedule_principal - principal_received : MoneyManager.default_zero_money
      overdue_interest           = schedule_interest > interest_received ? schedule_interest - interest_received : MoneyManager.default_zero_money
      installment_remaining      = last_payment_date.blank? ? all_schedules.size : all_schedules.select{|s| s.on_date >= last_payment_date}.size
      weeks_since_disbursal      = (loan.disbursal_date..@date).count/7
      weeks_remaining            = (@date..all_schedules.last.on_date).count/7
      installments_paid          = all_schedules.size-installment_remaining
      loan_end_date              = all_schedules.last.on_date
      last_complete_repayment_date = last_payment_date.blank? ? all_schedules.first.on_date : last_payment_date
      overdue_installment        = all_schedules.select{|s| s.on_date >= last_complete_repayment_date && s.on_date <= @date}.size
      days_overdue               = (last_complete_repayment_date..@date).count
      payment_scheme             = 'Not Specified'
      security_deposit           = 'Not Specified'
      land_holding               = 'Not Specified'
      land_holding_in_acres      = 'Not Specified'
      days_since_disbursal       = (loan.disbursal_date..Date.today).to_a.size
      days_remaining             = (Date.today..loan_end_date).to_a.size
      ro_name                    = managed_by_staff(center.id, @date)
      if @status == 'Live Loans'
        loan_closure_date        = ''
      else
        loan_closure_date        = loan.status == 'preclosed_loan_status' ? loan.preclosed_on_date : loan.repaid_on_date
      end
      source_of_fund_id          = NewFundingLine.get(FundingLineAddition.first(:lending_id => loan.id).funding_line_id).name
      meeting_address            = center.biz_location_address
      loan_outstanding_principal = loan_disbursed_amount > all_principal_received ? loan_disbursed_amount - all_principal_received : MoneyManager.default_zero_money
      loan_outstanding_interest  = loan_interest_amount > all_interest_received ? loan_interest_amount - all_interest_received : MoneyManager.default_zero_money

      data[:loans][loan.id] = {:member_name => member_name, :member_id => member_id,:member_address => member_address, :member_state => member_state,
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

end