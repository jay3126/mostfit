#This reports will generate monthly insurance report.
class MonthlyInsuranceReport < Report
  attr_accessor :from_date, :to_date, :branch_id

  validates_with_method :branch_id, :branch_should_be_selected

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 30
    @to_date = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @branch = Branch.get(params[:branch_id]) if params
    get_parameters(params, user)
  end

  def name
    "Monthly Insurance Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Monthly Insurance Report"
  end

  def generate
    data, hash = {}, {}
    hash = {:date_from.gte => @from_date, :date_from.lte => @to_date}     #this is for passing any arguments.
    hash1 = {:date_from.gte => @from_date, :date_from.lte => @to_date, "client.center.branch_id" => @branch_id}

    #getting client_ids according to the date filter on date_from of InsurancePolicy
    if @branch_id
      client_ids = InsurancePolicy.all(hash1).aggregate(:client_id)
    else
      client_ids = InsurancePolicy.all(hash).aggregate(:client_id)
    end

    #now iterating with each client and getting the values.
    client_ids.each do |client|

      cl = Client.get(client)

      data[cl.name]||={}

      #calculation of nfl_id, client_id and client_name.
      data[cl.name][:nfl_id] = cl.nfl_id
      data[cl.name][:client_id] = cl.id
      data[cl.name][:client_name] = cl.name

      #calculation of date_of_birth of client
      if cl.date_of_birth
        data[cl.name][:client_dob] = cl.date_of_birth
        data[cl.name][:client_age] = Time.now.year - cl.date_of_birth.year
      end

      #calculation fo client's center name, address and branch name.
      data[cl.name][:client_center_name] = cl.center.name
      data[cl.name][:client_center_address] = cl.center.address
      data[cl.name][:client_branch] = cl.center.branch.name.capitalize

      #calculation of loans of client, i.e., loan amount, disbursal_date, number_of_installments and installment_frequency.
      if cl.loans[0]
        data[cl.name][:loan_amount] = cl.loans[0].amount
        data[cl.name][:loan_disbursal_date] = cl.loans[0].disbursal_date
        data[cl.name][:loan_number_of_installments] = cl.loans[0].number_of_installments
        data[cl.name][:loan_installment_frequency] = cl.loans[0].installment_frequency.to_s
      else
        data[cl.name][:loan_amount] = "-"
        data[cl.name][:loan_disbursal_date] = "-"
        data[cl.name][:loan_number_of_installments] = "-"
        data[cl.name][:loan_installment_frequency] = "-"
      end
      
      data[cl.name][:client_spouse_name] = cl.spouse_name #client's spouse name.

      #calculation of insurance policy of loans of client. This is to get the sum_insured.
      if cl.loans[0] and cl.loans[0].insurance_policy
        data[cl.name][:loan_insurance_policy_sum_insured] = cl.loans[0].insurance_policy.sum_insured
      else
        data[cl.name][:loan_insurance_policy_sum_insured] = "-"
      end

      #calculation of loan purpose of client.
      if cl.loans[0] and cl.loans[0].occupation
        data[cl.name][:loan_purpose] = cl.loans[0].occupation.name.to_s.capitalize
      else
        data[cl.name][:loan_purpose] = "-"
      end
    end
    return data
  end
end
