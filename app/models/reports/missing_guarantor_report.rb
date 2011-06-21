#This is a report which will show the list of those clients whose guarantors are missing.
class MissingGuarantorReport < Report
  attr_accessor :branch, :branch_id

  validates_with_method :branch_id, :branch_should_be_selected

  def initialize(params, dates, user)
    @name = "Missing Guarantor Report for #{@branch}"
    @branch = Branch.get(params[:branch_id]) if params
    get_parameters(params, user)
  end

  def name
    "Missing Guarantor Report for #{@branch.name}"
  end

  def self.name
    "Missing Guarantor Report"
  end

  def generate
    data = {}

    #finding an array of client_id's who has guarantors attached to it restricted to a particular branch.
    client_ids_with_guarantors = Guarantor.all("client.center.branch_id" => @branch_id).aggregate(:client_id)

    #finding an aray of all the client_id's restricted to a particular branch.
    client_ids = Client.all("center.branch_id" => @branch_id).aggregate(:id)

    #substrating the two array's to get those client_id's who does not have guarantors attached to it.
    missing_guarantors_client_ids = client_ids - client_ids_with_guarantors

    #now iterating on the above array and finding out the details for reporting.
    missing_guarantors_client_ids.each do |i|
      c = Client.get(i)

      #since there were some clients without loans so we have an if condition so that the code does not craps out.
      if c.loans.length > 0
        id = c.loans[0].id
        loan_amount = c.loans[0].amount
        date_of_disbursal = c.loans[0].disbursal_date
        loan_status = c.loans[0].status
      else
        id = loan_amount = date_of_disbursal = "-"
        loan_status = "No loans"
      end

      #this is because there are some cases where occupation is nil.
      if c.occupation  
        data[c.name] = {:id => c.id, :name => c.name, :reference => c.reference, :gender => c.gender, :date_of_birth => c.date_of_birth,
          :branch => c.center.branch.name, :occupation => c.occupation.name, :loan_id => id, :loan_amount => loan_amount,
          :loan_disbursal_date => date_of_disbursal, :loan_status => loan_status}
      else
        data[c.name] = {:id => c.id, :name => c.name, :reference => c.reference, :gender => c.gender, :date_of_birth => c.date_of_birth,
          :branch => c.center.branch.name, :occupation => "-", :loan_id => id, :loan_amount => loan_amount,
          :loan_disbursal_date => date_of_disbursal, :loan_status => loan_status}
      end
    end
    return data
  end

  def branch_should_be_selected
    return [false, "Branch should be selected"] if branch_id.blank?
    return true
  end
end
