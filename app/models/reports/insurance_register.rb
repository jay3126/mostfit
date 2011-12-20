class InsuranceRegister < Report
  attr_accessor :date

  def initialize(params, dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    @name   = "Insurance Report of #{date}"
    get_parameters(params, user)
  end

  def self.name
    "Insurance Register"
  end

  def name
    "Insurance Report of #{date}"
  end

  def generate
    #this report has been modified according to Moral needs.
    data = {}

    Loan.all(:disbursal_date => @date).each do |l|

      loan_id = l.id
      loan_amount = l.amount
      loan_disbursal_date = l.disbursal_date

      client = Client.get(l.client_id)
      client_id = l.client_id
      client_name = client.name
      if client.date_of_birth
        client_age = (Time.now.year - client.date_of_birth.year)
      else
        client_age = "NA"
      end

      if client.spouse_name
        client_spouse_name = client.spouse_name
      else
        client_spouse_name = "NA"
      end

      if client.spouse_date_of_birth
        client_spouse_age = (Time.now.year - client.spouse_date_of_birth.year)
      else
        client_spouse_age = "NA"
      end

      center = Center.get(l.c_center_id)
      center_id = l.c_center_id
      center_name = center.name

      branch = Branch.get(l.c_branch_id)
      branch_id = l.c_branch_id
      branch_name = branch.name

      data[l.id] = {:loan_id => loan_id, :loan_amount => loan_amount, :loan_disbursal_date => loan_disbursal_date, :client_id => client_id,
      :client_name => client_name, :client_age => client_age, :client_spouse_name => client_spouse_name, :client_spouse_age => client_spouse_age,
      :center_id => center_id, :center_name => center_name, :branch_id => branch_id, :branch_name => branch_name}
    end
    return data
  end

  def branch_should_be_selected
    return [false, "Branch should be selected"] if branch_id.blank?
    return true
  end
end
