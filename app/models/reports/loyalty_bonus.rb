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
    # at last we have a candidate for refactoring into a really nice bulk selection method.
    # the problem with all the listing reports is that they all need to get nested information and this slows them down loads as they make repeated calls to the database
    # our plan is to preload all the required nested data with one call per model.
    # we should be able to define the report as
    # :loans => LoanHistory.all(....).aggregate(:id, :client_id, :center_id, :branch_id)
    # :fields => {:client => :name, :client.center.branch => :code, :client.center => :meeting_day}
    # but first the non refactored version

    # first get [:loan_id, :date] for all loan_history where status is repaid abd last status is outstanding
    debugger
    conds = {:status => [:preclosed, :repaid], :date => @from_date..@to_date, :last_status => [:outstanding]}.merge!(@branch_id ? {:branch_id => @branch_id} : {})

    keys = [:branch, :center, :client_group, :client]
    debugger
    required_fields = LoanHistory.all(conds).aggregate(*([:loan_id] + keys.map{|k| "#{k.to_s}_id".to_sym} + [:date]))
    return {} if required_fields.blank?
    # Get the names of everything that is in the array
    keys.each_with_index do |k,i| 
      debugger
      model = Kernel.const_get(k.to_s.camel_case) # i.e. Branch
      instance_variable_set("@#{k}_names", model.all(:id => required_fields.map{|x| x[i+1]}).aggregate(:id, :name).to_hash)
      # i.e. @branch = Branch.all(:id => required_fields.map{|x| x[1]})
    end
    required_field_hash = required_fields.map{|x| [x[0], x[1..-1]]}.to_hash
    @data = required_field_hash.map do |lid, data_array| #data_array = [:branch_id, :center_id, :client_group_id, :client_id, :date] 
      bname = @branch_names[data_array[0]] rescue nil
      mat_date = data_array[-1]
      l = Loan.get(lid)
      {:loan                                    =>l, 
        :branch_name                            => bname,
        :branch_id                              => data_array[0],
        :client_name                            => @client_names[data_array[3]], # inelegant!
        :client_id                              => data_array[3],
        :center_name                            => @center_names[data_array[1]], # bug prone!
        :center_id                              => data_array[1],
        :number_of_installments                 => l.number_of_installments, 
        :absents                                => l.client.attendances(:date => l.disbursal_date..mat_date, :status => "absent").count, 
        :attendance                             => l.client.attendances(:date => l.disbursal_date..mat_date).count, 
        :mat_date                               => mat_date,
        :paid                                   => l.client.loyalty_bonus_paid}
    end
  end
  
end
