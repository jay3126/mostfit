class DelinquencySofReport < Report
  attr_accessor :date, :funding_line_id, :page

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Delinquency Report SOF"
    @user = user
    @user = user
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : []
    get_parameters(params, user)
  end

  def name
    "Delinquency Sof Report for #{@date}"
  end

  def self.name
    "Delinquency Sof Report"
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
    loan_due_statuses = []
    loan_hash = {}
    loan_status = ['Current Loans', '1-29 Days', '30-59 Days', '60-89 Days', '90-119 Days', '120-149 Days', '150-179 Days', 'Above 180 Days']
    data[:status] = loan_status
    all_due_statuses = get_reporting_facade(@user).get_loan_due_status_for_sof_on_date(@date, @funding_line_id)
    data[:records] = {}
    all_due_statuses.each do |funding_line, loan_due_statuses|
      data[:records][funding_line] = {}
      loan_hash['Current Loans'] = loan_due_statuses.select{|s| s.day_past_due == 0}
      loan_hash['1-29 Days'] = loan_due_statuses.select{|s| s.day_past_due >= 1 and s.day_past_due <= 29}
      loan_hash['30-59 Days']= loan_due_statuses.select{|s| s.day_past_due >= 30 and s.day_past_due <= 59}
      loan_hash['60-89 Days'] = loan_due_statuses.select{|s| s.day_past_due >= 60 and s.day_past_due <= 89}
      loan_hash['90-119 Days'] = loan_due_statuses.select{|s| s.day_past_due >= 90 and s.day_past_due <= 119}
      loan_hash['120-149 Days'] = loan_due_statuses.select{|s| s.day_past_due >= 120 and s.day_past_due <= 149}
      loan_hash['150-179 Days'] = loan_due_statuses.select{|s| s.day_past_due >= 150 and s.day_past_due <= 179}
      loan_hash['Above 180 Days'] = loan_due_statuses.select{|s| s.day_past_due >= 180}

      loan_hash.each do |status, values|
        l_ids = values.blank? ? [] : values.map(&:lending_id).uniq
        loan_count = l_ids.count
        disbursed_amt = l_ids.blank? ? [] : LoanBaseSchedule.all(:lending_id => l_ids).aggregate(:total_loan_disbursed.sum, :total_interest_applicable.sum)
        disbursed_principal_money_amt = l_ids.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(disbursed_amt[0].to_i)
        disbursed_interest_money_amt = l_ids.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(disbursed_amt[1].to_i)
        total_loan_disbursed = disbursed_principal_money_amt + disbursed_interest_money_amt
        loan_receipts = l_ids.blank? ? [] : LoanReceipt.all(:lending_id => l_ids, :effective_on.lte => @date)
        loan_recevied_amt = LoanReceipt.add_up(loan_receipts)
        scheduled_principal_outstanding = values.map(&:scheduled_principal_outstanding).sum
        scheduled_interest_outstanding = values.map(&:scheduled_interest_outstanding).sum
        scheduled_principal_outstanding_amt = l_ids.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(scheduled_principal_outstanding.to_i)
        scheduled_interest_outstanding_amt = l_ids.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(scheduled_interest_outstanding.to_i)
        scheduled_principal_on_date = l_ids.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(values.map(&:scheduled_principal_due).sum.to_i)
        scheduled_interest_on_date = l_ids.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(values.map(&:scheduled_interest_due).sum.to_i)
        scheduled_principal_due_till_date = (disbursed_principal_money_amt - scheduled_principal_outstanding_amt)
        scheduled_interest_due_till_date = (disbursed_interest_money_amt - scheduled_interest_outstanding_amt)
        received_principal_till_date = loan_recevied_amt[:principal_received]
        received_interest_till_date = loan_recevied_amt[:interest_received]
        outstanding_principal = disbursed_principal_money_amt > received_principal_till_date ? disbursed_principal_money_amt - received_principal_till_date : MoneyManager.default_zero_money
        outstanding_interest = disbursed_interest_money_amt > received_interest_till_date ?  disbursed_interest_money_amt - received_interest_till_date : MoneyManager.default_zero_money
        total_outstanding = outstanding_principal + outstanding_interest
        overdue_principal = scheduled_principal_due_till_date > received_principal_till_date ? scheduled_principal_due_till_date - received_principal_till_date : MoneyManager.default_zero_money
        overdue_interest = scheduled_interest_due_till_date > received_interest_till_date ? scheduled_interest_due_till_date - received_interest_till_date : MoneyManager.default_zero_money
        if overdue_principal > MoneyManager.default_zero_money
          par_value = (overdue_principal.amount.to_f)/(outstanding_principal.amount.to_f)
          par = ('%.3f' % par_value)
        else
          par = 0.0
        end
        data[:records][funding_line][status] = {:status => status, :loans_count => loan_count, :loan_amount => total_loan_disbursed, :principal_disbursed => disbursed_principal_money_amt, :interest_disbursed => disbursed_interest_money_amt, :outstanding => total_outstanding, :outstanding_principal => outstanding_principal, :outstanding_interest => outstanding_interest, :overdue_principal => overdue_principal, :overdue_interest => overdue_interest, :par => par}
      end
    end
    data
  end
end