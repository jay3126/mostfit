class ClientWiseOutstandingReport < Report

  attr_accessor :from_date, :to_date, :branch, :branch_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    @branch_ids = (params and params[:branch_id] and (not (params[:branch_id].empty?))) ? [params[:branch_id]] : Branch.all.aggregate(:id)
    get_parameters(params, user)
 end

  def name
    "Client Wise Outstanding report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Client Wise Outstanding Report (for loans disbursed between date range)"
  end

  def generate
    data = {}

    params = {:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date, :c_branch_id => @branch_ids}
    loan_ids = Loan.all(params).aggregate(:id)
    date1 = @to_date

    loan_ids.each do |l|
      loan = Loan.get(l)

      loan_id = loan.id
      loan_amount = (loan and loan.amount) ? loan.amount : "Not Specified"
      loan_disbursal_date = (loan and loan.disbursal_date) ? loan.disbursal_date : "Not Disbursed Yet"
      loan_purpose = (loan and loan.occupation and (not loan.occupation.nil?)) ? loan.occupation.name : "Loan Purpose not specified"
      loan_interest_rate = (loan and loan.interest_rate) ? (loan.interest_rate * 100) : "Interest Rate not specified"
      loan_status = loan.status
      loan_cycle_number = (loan and loan.cycle_number) ? loan.cycle_number : "Not Specified"
      loan_installment_frequency = (loan and loan.installment_frequency) ? loan.installment_frequency : "Not Specified"
      loan_number_of_installments = (loan and loan.number_of_installments) ? loan.number_of_installments : "Not Specified"
      loan_product = (loan and loan.loan_product) ? loan.loan_product.name : "Not Specified"

      loan_history_as_on_date1 = loan.loan_history(:date.lte => date1).last
      principal_outstanding_as_on_date1 = loan_history_as_on_date1.actual_outstanding_principal
      # interest_outstanding_as_on_date1 = loan_history_as_on_date1.actual_outstanding_interest
      # scheduled_principal_outstanding_as_on_date1 = loan_history_as_on_date1.scheduled_outstanding_principal
      # scheduled_interest_outstanding_as_on_date1 = (loan_history_as_on_date1.scheduled_outstanding_total - loan_history_as_on_date1.scheduled_outstanding_principal)

      if loan.payments(:type => [:principal, :interest]).empty?
        loan_first_repayment_date = loan.scheduled_first_payment_date
      else
        loan_first_repayment_date = loan.payments(:type => [:principal, :interest]).min(:received_on)
      end

      loan_payments = loan.payments(:received_on.lte => date1, :type => [:principal, :interest])
      last_payment_date_before_date1 = (loan_payments and not (loan_payments.empty?)) ? loan_payments.last.received_on : "No Payments received yet"

      client = Client.get(loan.client_id)
      client_id = client.id
      client_name = client.name
      client_group = (client and client.client_group and (not client.client_group.nil?)) ? client.client_group.name : "Not attached to any group"
      client_caste = (client and client.caste and (not client.caste.nil?)) ? client.caste.capitalize : "Caste not specified"
      client_religion = (client and client.religion and (not client.religion.nil?)) ? client.religion.capitalize : "Religion not specified"
      client_gender = (client and client.gender and (not client.gender.nil?)) ? client.gender : "Gender not specified"

      center = Center.get(loan.c_center_id)
      center_id = center.id
      center_name = center.name

      branch = Branch.get(loan.c_branch_id)
      branch_id = branch.id
      branch_name = branch.name

      data[loan] = {:branch_id => branch_id, :branch_name => branch_name, :center_id => center_id, :center_name => center_name,
        :client_id => client_id, :client_name => client_name, :client_group => client_group, :loan_id => loan_id, :loan_amount => loan_amount,
        :loan_disbursal_date => loan_disbursal_date, :loan_purpose => loan_purpose, :loan_interest_rate => loan_interest_rate,
        :client_caste => client_caste, :client_religion => client_religion, :loan_status => loan_status, :loan_cycle_number => loan_cycle_number,
        :loan_installment_frequency => loan_installment_frequency, :loan_number_of_installments => loan_number_of_installments,
        :loan_product => loan_product, :principal_outstanding_as_on_date1 => principal_outstanding_as_on_date1, :client_gender => client_gender,
        :loan_first_repayment_date => loan_first_repayment_date, :last_payment_date_before_date1 => last_payment_date_before_date1
      }
    end
    data
  end
end
