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
    r = repository.adapter.query(%Q{
                                    SELECT c.id as client_id, l.id as loan_id, l.amount, c.name as client_name, c.spouse_name as client_spouse_name, c.spouse_date_of_birth as spouse_date_of_birth, l.disbursal_date, b.name as branch_name, cen.name as center_name, ip.nominee as nominee_name   
                                    FROM clients c, loans l, branches b, centers cen, insurance_policies ip 
                                    WHERE l.client_id = c.id AND l.c_branch_id = b.id AND l.c_center_id = cen.id AND l.disbursal_date >= '#{from_date.strftime('%Y-%m-%d')}' AND l.disbursal_date <= '#{to_date.strftime('%Y-%m-%d')}' AND c.active = true AND b.id = #{@branch_id} AND cen.branch_id = b.id AND ip.client_id = c.id AND ip.loan_id = l.id
                                    ORDER by l.disbursal_date, c.id})
  end

  def branch_should_be_selected
    return [false, "Branch should be selected"] if branch_id.blank?
    return true
  end
end
