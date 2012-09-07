class PreClosureCustomerDetails < Report
  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Consolidated Report from #{@from_date} to #{@to_date}"
    @user = user
    get_parameters(params, user)
  end

  def name
    "Pre-Closure Customer Details Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Pre-Closure Customer Details "
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate

    data = {}
    lendings = LoanStatusChange.status_between_dates(LoanLifeCycle::REPAID_LOAN_STATUS, @from_date, @to_date).lending
    lendings.each do |loan|
      member                    = loan.loan_borrower.counterparty
      status_date               = loan.loan_status_changes(:to_status => LoanLifeCycle::REPAID_LOAN_STATUS).first.effective_on
      remarks                   = loan.remarks.blank? ? '' : loan.remarks rescue ''
      reason                    = ''
      pre_closure_amount        = Money.new(loan.loan_receipts.aggregate(:principal_received.sum).to_i, default_currency)
      fee_instances             = FeeInstance.unpaid_loan_preclosure_fee_instance(loan.id)
      fee_receipts              = fee_instances.blank? ? '' : fee_instances.fee_receipt.to_money[:fee_amount] unless
      pre_closure_charges       = fee_receipts.blank? ? MoneyManager.default_zero_money : fee_receipts.sum
      pre_closure_other_charges = MoneyManager.default_zero_money
      loan_account_number       = loan.lan
      member_name               = member ? member.name : "Not Specified"
      center                    = loan.administered_at_origin_location
      center_id                 = center ? center.id : "Not Specified"
      center_name               = center ? center.name : "Not Specified"
      branch                    = loan.accounted_at_origin_location
      branch_name               = branch ? branch.name : "Not Specified"
      branch_id                 = branch ? branch.id : "Not Specified"

      data[loan.id] = {:member_name => member_name, :center_name => center_name, :center_id => center_id,
        :branch_name => branch_name, :branch_id => branch_id,
        :on_date => status_date, :remarks => remarks, :reason => reason,
        :pre_closure_amount => pre_closure_amount, :pre_closure_charges => pre_closure_charges, :pre_closure_other_charges => pre_closure_other_charges,
        :loan_account_number => loan_account_number}
    end
    data
  end

end
