class InsuranceRegister < Report
  attr_accessor :from_date, :to_date, :branch, :branch_id

  validates_with_method :branch_id, :branch_should_be_selected

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def self.name
    "Insurance Register"
  end

  def name
    "Insurance Register from #{@from_date} to #{@to_date}"
  end

  def generate
    insurance_policies = InsurancePolicy.all(:date_from => @from_date..@to_date, 'client.center.branch_id' => @branch_id)
    clients = insurance_policies.clients.map{|c| [c.id, c]}.to_hash
    loans = insurance_policies.loans.map{|l| [l.id, l]}.to_hash
    guarantors = insurance_policies.clients.guarantors.map{|g| [g.client_id, g]}.to_hash
    return {:clients => clients, :loans => loans, :guarantors => guarantors, :insurance_policies => insurance_policies}
  end

  def branch_should_be_selected
    return [false, "Branch should be selected"] if branch_id.blank?
    return true
  end
end
