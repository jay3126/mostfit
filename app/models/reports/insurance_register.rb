class InsuranceRegister < Report
  attr_accessor :from_date, :to_date, :branch, :branch_id


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
    hash = {:disbursal_date => @from_date..@to_date}.merge(@branch_id ? {:c_branch_id => @branch_id} : {})
    loans = Loan.all(hash)
    clients = Client.all(:id => loans.aggregate(:client_id)).map{|c| [c.id, {:client => c, :loans => []}]}.to_hash
    loans.each{|l| clients[l.client_id][:loans].push(l)}
    return clients
  end

  def branch_should_be_selected
    return [false, "Branch should be selected"] if branch_id.blank?
    return true
  end
end
