class LoanAccountStatementReport < Report
  attr_accessor :loan_lan_number

  #validates_with_method :loan_lan_number, :lan_number_should_be_selected

  def initialize(params, dates, user)
    @lan_number = (params and params[:loan_lan_number]) ? params[:loan_lan_number] : ""
    @name = "Loan Account Statement for #{@lan_number}"
    @user = user
    get_parameters(params, user)
  end

  def name
    "Loan Account Statement for #{@lan_number}"
  end

  def self.name
    "Loan Account Statement Report"
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
    data = {:customer_info => {}, :loan_info => {}, :charge_history => {}, :repayments_history => {}}
    loan = Lending.first(:lan => @lan_number)
    unless loan.blank?
      member = loan.loan_borrower.counterparty
      if member.blank?
        member_id =  member_address = ''
        member_name = 'Not Specified'
      else
        member_id       = member.id
        member_name     = member.name
        member_address  = member.address
      end
      loan_purpose               = loan.loan_purpose.blank? ? 'Not Specified' : loan.loan_purpose
      loan_cycle                 = ''
      loan_status                = loan.status
      loan_start_date            = loan.scheduled_first_repayment_date
      loan_end_date              = loan.last_scheduled_date
      loan_disbursed_date        = loan.disbursal_date
      loan_tenure                = loan.lending_product.tenure
      loan_disbursed_amount      = loan.to_money[:disbursed_amount]
      oustanding_with_overdue    = get_reporting_facade(@user).sum_outstanding_amounts_including_overdues(loan.id, Date.today)
      outs_principalwith_overdue = oustanding_with_overdue[:principal_outstanding_including_overdues]
      outs_interest_with_overdue = oustanding_with_overdue[:interest_outstanding_including_overdues]
      overdue_amount             =  get_reporting_facade(@user).overdue_amounts(loan.id, Date.today)
      overdue_principal          = overdue_amount[:principal_overdue_amount]
      overdue_interest           = overdue_amount[:interest_overdue_amount]
      loan_installment           = get_reporting_facade(@user).number_of_installments_per_loan(loan.id)
      installment_remaining      = loan_installment[:installments_remaining]
      installment_fallen_due     = installment_remaining == loan_tenure ? 1 : loan_tenure-installment_remaining
      total_amount_paid          = loan.total_received_till_date
      loan_scheduled_dates       = loan.schedule_dates
      loan_repayments            = loan.loan_receipts.group_by{|lr| lr.effective_on}.to_a
      fee_instances              = FeeInstance.all_fee_instances_on_loan(loan.id)
      center                     = loan.administered_at_origin_location
      center_id                  = center ? center.id : "Not Specified"
      center_name                = center ? center.name : "Not Specified"
      branch                     = loan.accounted_at_origin_location
      branch_name                = branch ? branch.name : "Not Specified"
      branch_id                  = branch ? branch.id : "Not Specified"
      fee_instances.each do |fee_instance|
        schedule_date  =  fee_instance.created_at
        payment_date   = fee_instance.is_collected? ? fee_instance.fee_receipt.effective_on : ''
        due_amount     = fee_instance.money_amount
        paid_amount    = fee_instance.is_collected? ? fee_instance.fee_receipt.fee_money_amount : MoneyManager.default_zero_money
        data[:charge_history][fee_instance.id] ={:schedule_date => schedule_date, :payment_date => payment_date, :due_amount => due_amount, :paid_amount => paid_amount}
      end

      max_rang = [loan_scheduled_dates.size, loan_repayments.size].max
      (0..max_rang).each do |value|
        schedule_date  = loan_scheduled_dates[value+1]
        payment_date   = loan_repayments[value].blank? ? '' : loan_repayments[value].first
        next if schedule_date.blank? && payment_date.blank?
        principal_due  = schedule_date.blank? ? MoneyManager.default_zero_money : loan.scheduled_principal_due(schedule_date)
        interest_due   = schedule_date.blank? ? MoneyManager.default_zero_money : loan.scheduled_interest_due(schedule_date)
        total_due      = principal_due + interest_due
        principal_paid = loan_repayments[value].blank? ? MoneyManager.default_zero_money : Money.new(loan_repayments[value].last.map(&:principal_received).sum.to_i, default_currency)
        interest_paid  = loan_repayments[value].blank? ? MoneyManager.default_zero_money : Money.new(loan_repayments[value].last.map(&:interest_received).sum.to_i, default_currency)
        total_paid     = principal_paid + interest_paid

        data[:repayments_history][value] = {:schedule_date => schedule_date, :payment_date => payment_date,
          :principal_due => principal_due, :interest_due => interest_due, :total_due => total_due,
          :principal_paid => principal_paid, :interest_paid => interest_paid, :total_paid => total_paid}
      end
      data[:customer_info] = {:member_name => member_name, :member_id => member_id, :member_address => member_address, :center_name =>  center_name,
        :loan_purpose => loan_purpose, :loan_cycle => loan_cycle, :loan_status => loan_status}
      data[:loan_info] = {:loan_number => @lan_number, :loan_start_date => loan_start_date, :loan_end_date => loan_end_date, :total_installments => loan_tenure,
        :disbursal_date => loan_disbursed_date, :outstanding_principal_with_overdue => outs_principalwith_overdue, :outstanding_interset_with_overdue => outs_interest_with_overdue,
        :overdue_principal => overdue_principal, :overdue_interest => overdue_interest, :installment_fallen_due => installment_fallen_due,
        :disbursed_amount => loan_disbursed_amount,:installment_remaining => installment_remaining, :total_amount_paid => total_amount_paid}
    end
    data
  end

  def lan_number_should_be_selected
    @lan_number.blank? ? true : [false, "LAN Number should be selected"]
  end
end
