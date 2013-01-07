class LoanDisbursementReport < Report

  attr_accessor :from_date, :to_date, :branch, :branch_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    @branch_ids = (params and params[:branch_id] and (not (params[:branch_id].empty?))) ? [params[:branch_id]] : Branch.all.aggregate(:id)
    get_parameters(params, user)
 end

  def name
    "Loan disbursement report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Loan Disbursment Report"
  end

  def generate
    data = {}

    params = {:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date, :c_branch_id => @branch_ids}
    loan_ids = Loan.all(params).aggregate(:id)

    loan_ids.each do |l|
      loan = Loan.get(l)

      loan_id = loan.id
      loan_amount = (loan and loan.amount) ? loan.amount : "Not Specified"
      loan_disbursal_date = (loan and loan.disbursal_date) ? loan.disbursal_date : "Not Disbursed Yet"
      loan_purpose = (loan and loan.occupation and (not loan.occupation.nil?)) ? loan.occupation.name : "Loan Purpose not specified"
      loan_interest_rate = (loan and loan.interest_rate) ? (loan.interest_rate * 100) : "Interest Rate not specified"

      client = Client.get(loan.client_id)
      client_id = client.id
      client_name = client.name
      client_group = (client and client.client_group and (not client.client_group.nil?)) ? client.client_group.name : "Not attached to any group"

      center = Center.get(loan.c_center_id)
      center_id = center.id
      center_name = center.name

      branch = Branch.get(loan.c_branch_id)
      branch_id = branch.id
      branch_name = branch.name

      data[loan] = {:branch_id => branch_id, :branch_name => branch_name, :center_id => center_id, :center_name => center_name, :client_id => client_id, :client_name => client_name,
        :client_group => client_group, :loan_id => loan_id, :loan_amount => loan_amount, :loan_disbursal_date => loan_disbursal_date, :loan_purpose => loan_purpose, :loan_interest_rate => loan_interest_rate
      }
    end
    data
  end
end