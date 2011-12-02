class LoyaltyBonus < Report
  # from_date = for clients added after or on from date
  # to_date   = clients added before or on to_date
  
  attr_accessor :from_date, :to_date, :branch, :branch_id
  
  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end
  
  def self.name
    "Loyalty Bonus"
  end
  
  def name
    "Clients Eligible for Loyalty Bonus from #{@from_date} to #{@to_date}"
  end

  def generate
    # first get [:loan_id, :date] for all loan_history where status is repaid abd last status is outstanding
    conds = {:status => [:preclosed, :repaid], :date => @from_date..@to_date, :last_status => [:outstanding]}.merge!(@branch_id ? {:branch_id => @branch_id} : {})
    _i = LoanHistory.all(conds).aggregate(:loan_id, :date)
    #then get [client, number_of_installments, attendance]
    @date = _i.to_hash.map do |lid, mat_date| 
      l = Loan.get(lid)
      {:loan                               =>l, 
        :client                            => l.client, 
        :number_of_installments            => l.number_of_installments, 
        :absents                           => l.client.attendances(:date => l.disbursal_date..mat_date, :status => "absent").count, 
        :attendance                        => l.client.attendances(:date => l.disbursal_date..mat_date).count, 
        :mat_date                          => mat_date}
    end
  end
  
end
