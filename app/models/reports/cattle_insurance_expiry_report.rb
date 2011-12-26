#This gives a list of those clients whose Cattle insurance expires during a date range.
#This is Intellecash specific.
class CattleInsuranceExpiryReport < Report

  attr_accessor :from_date, :to_date

  #validates_with_method :branch_id, :branch_should_be_selected

  def initialize(params, dates, user)
    @name = "Cattle Insurance Expiry Report"
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today
    @to_date = (dates and dates[:to_date]) ? dates[:to_date] : Date.today + 30
    get_parameters(params, user)
  end

  def name
    "Cattle Insurance Expiry Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Cattle Insurance Expiry Report"
  end

  def generate

    data = {}

    InsurancePolicy.all(:cover_for => :cattle, :date_to.gte => @from_date, :date_to.lte => @to_date).each do |ip|

      loan_id = ip.loan_id

      client = ip.client
      client_id = client.id
      client_name = client.name

      insurance_id = ip.id
      application_number = ip.application_number
      policy_number = ip.policy_no
      cover_for = ip.cover_for
      sum_insured = ip.sum_insured
      premium = ip.premium
      insurance_start_date = ip.date_from
      insurance_end_date = ip.date_to

      center = ip.client.center
      center_id = center.id
      center_name = center.name

      branch = ip.client.center.branch
      branch_id = branch.id
      branch_name = branch.name

      data[ip.id] = {:branch_id => branch.id, :branch_name => branch.name, :center_id => center.id, :center_name => center.name,
        :client_id => client.id, :client_name => client.name, :loan_id => loan_id, :insurance_id => insurance_id,
        :application_number => application_number, :policy_number => policy_number, :cover_for => cover_for, :sum_insured => sum_insured,
        :premium => premium, :insurance_start_date => insurance_start_date, :insurance_end_date => insurance_end_date}
    end
    return data
  end
end
