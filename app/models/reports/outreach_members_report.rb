class OutreachMembersReport < Report

  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Outreach Members Report from #{@from_date} to #{@to_date}"
    @user = user
    get_parameters(params, user)
  end

  def name
    "Outreach Members Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Outreach Members Report"
  end

  def get_reporting_facade(user)
    @reporting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, user)
  end

  def get_location_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user)
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate
    location_facade  = get_location_facade(@user)
    #since Suryoday has 1:1 mapping between Loan and Client, so we are counting number of loans = number of members.
    data = {:members_by_caste => {}, :members_by_religion => {}, :members_by_loan_cycle => {}, :members_by_loan_product => {}, :members_by_branch => {}, :members_by_classification => {}, :members_by_psl => {}}

    #members by caste
    caste_master_list = Constants::Masters::CASTE_CHOICE
    caste_master_list.each do |caste|
      caste_name = caste.to_s.humanize
      opening_balance = Lending.all(:applied_on_date.lt => @from_date).select{|ob| ob.borrower_caste == caste}.count
      new_loans_added_during_period = Lending.all(:applied_on_date.gte => @from_date, :applied_on_date.lte => @to_date).select{|nla| nla.borrower_caste == caste}.count
      loan_closed_during_period = Lending.all(:repaid_on_date.gte => @from_date, :repaid_on_date.lte => @to_date, :status => :repaid_loan_status).select{|cl| cl.borrower_caste == caste}.count
      loan_preclosed_during_period = Lending.all(:preclosed_on_date.gte => @from_date, :preclosed_on_date.lte => @to_date, :status => :preclosed_loan_status).select{|lp| lp.borrower_caste == caste}.count
      client_count_at_end_of_period = Lending.all(:applied_on_date.lte => @to_date).select{|c| c.borrower_caste == caste}.count

      data[:members_by_caste][caste] = {:caste_name => caste_name, :opening_balance => opening_balance, :new_loans_added_during_period => new_loans_added_during_period, :loan_closed_during_period => loan_closed_during_period, :loan_preclosed_during_period => loan_preclosed_during_period, :client_count_at_end_of_period => client_count_at_end_of_period}
    end

    #members by religion
    religion_master_list = Constants::Masters::RELIGION_CHOICE
    religion_master_list.each do |religion|
      religion_name = religion.to_s.humanize
      opening_balance = Lending.all(:applied_on_date.lt => @from_date).select{|ob| ob.borrower_religion == religion}.count
      new_loan_count_added_during_period = Lending.all(:applied_on_date.gte => @from_date, :applied_on_date.lte => @to_date).select{|nl| nl.borrower_religion == religion}.count
      loan_closed_during_period = Lending.all(:repaid_on_date.gte => @from_date, :repaid_on_date.lte => @to_date, :status => :repaid_loan_status).select{|cl| cl.borrower_religion == religion}.count
      loan_preclosed_during_period = Lending.all(:preclosed_on_date.gte => @from_date, :preclosed_on_date.lte => @to_date, :status => :preclosed_loan_status).select{|pl| pl.borrower_religion == religion}.count        
      client_count_at_end_of_period = Lending.all(:applied_on_date.lte => @to_date).select{|cl| cl.borrower_religion == religion}.count

      data[:members_by_religion][religion] = {:religion_name => religion_name, :opening_balance => opening_balance, :new_loan_count_added_during_period => new_loan_count_added_during_period, :loan_closed_during_period => loan_closed_during_period, :loan_preclosed_during_period => loan_preclosed_during_period, :client_count_at_end_of_period => client_count_at_end_of_period}
    end

    #members by loan_cycle
    cycle_number_master = Lending.all.aggregate(:cycle_number)
    cycle_number_master.each do |loan_cycle_number|
      opening_balance = Lending.all(:applied_on_date.lt => @from_date, :cycle_number => loan_cycle_number).count
      new_loan_count_added_during_period = Lending.all(:applied_on_date.gte => @from_date, :applied_on_date.lte => @to_date, :cycle_number => loan_cycle_number).count
      loan_closed_during_period = Lending.all(:repaid_on_date.gte => @from_date, :repaid_on_date.lte => @to_date, :status => :repaid_loan_status, :cycle_number => loan_cycle_number).count
      loan_preclosed_during_period = Lending.all(:preclosed_on_date.gte => @from_date, :preclosed_on_date.lte => @to_date, :status => :preclosed_loan_status, :cycle_number => loan_cycle_number).count        
      client_count_at_end_of_period = Lending.all(:applied_on_date.lte => @to_date, :cycle_number => loan_cycle_number).count

      data[:members_by_loan_cycle][loan_cycle_number] = {:cycle_number => loan_cycle_number, :opening_balance => opening_balance, :new_loan_count_added_during_period => new_loan_count_added_during_period, :loan_closed_during_period => loan_closed_during_period, :loan_preclosed_during_period => loan_preclosed_during_period, :client_count_at_end_of_period => client_count_at_end_of_period}
    end

    #members by loan_product
    loan_product_master = LendingProduct.all
    loan_product_master.each do |loan_product|
      opening_balance = Lending.all(:applied_on_date.lt => @from_date, :lending_product_id => loan_product.id).count
      new_loan_count_added_during_period = Lending.all(:applied_on_date.gte => @from_date, :applied_on_date.lte => @to_date, :lending_product_id => loan_product.id).count
      loan_closed_during_period = Lending.all(:repaid_on_date.gte => @from_date, :repaid_on_date.lte => @to_date, :status => :repaid_loan_status, :lending_product_id => loan_product.id).count
      loan_preclosed_during_period = Lending.all(:preclosed_on_date.gte => @from_date, :preclosed_on_date.lte => @to_date, :status => :preclosed_loan_status, :lending_product_id => loan_product.id).count        
      client_count_at_end_of_period = Lending.all(:applied_on_date.lte => @to_date, :lending_product_id => loan_product.id).count

      data[:members_by_loan_product][loan_product] = {:loan_product => loan_product.name, :opening_balance => opening_balance, :new_loan_count_added_during_period => new_loan_count_added_during_period, :loan_closed_during_period => loan_closed_during_period, :loan_preclosed_during_period => loan_preclosed_during_period, :client_count_at_end_of_period => client_count_at_end_of_period}
    end

    #members_by_branch
    branch_master = location_facade.all_nominal_branches
    branch_master.each do |branch|
      opening_balance = Lending.all(:applied_on_date.lt => @from_date, :accounted_at_origin => branch.id).count
      new_loan_count_added_during_period = Lending.all(:applied_on_date.gte => @from_date, :applied_on_date.lte => @to_date, :accounted_at_origin => branch.id).count
      loan_closed_during_period = Lending.all(:repaid_on_date.gte => @from_date, :repaid_on_date.lte => @to_date, :status => :repaid_loan_status, :accounted_at_origin => branch.id).count
      loan_preclosed_during_period = Lending.all(:preclosed_on_date.gte => @from_date, :preclosed_on_date.lte => @to_date, :status => :preclosed_loan_status, :accounted_at_origin => branch.id).count        
      client_count_at_end_of_period = Lending.all(:applied_on_date.lte => @to_date, :accounted_at_origin => branch.id).count

      data[:members_by_branch][branch] = {:branch_name => branch.name, :opening_balance => opening_balance, :new_loan_count_added_during_period => new_loan_count_added_during_period, :loan_closed_during_period => loan_closed_during_period, :loan_preclosed_during_period => loan_preclosed_during_period, :client_count_at_end_of_period => client_count_at_end_of_period}
    end

    #members by classification
    town_classification_master_list = Constants::Masters::TOWN_CLASSIFICATION
    town_classification_master_list.each do |classification|
      classification_name = classification.to_s.humanize
      opening_balance = Lending.all(:applied_on_date.lt => @from_date).select{|ob| ob.borrower_town_classification == classification}.count
      new_loan_count_added_during_period = Lending.all(:applied_on_date.gte => @from_date, :applied_on_date.lte => @to_date).select{|nl| nl.borrower_town_classification == classification}.count
      loan_closed_during_period = Lending.all(:repaid_on_date.gte => @from_date, :repaid_on_date.lte => @to_date, :status => :repaid_loan_status).select{|cl| cl.borrower_town_classification == classification}.count
      loan_preclosed_during_period = Lending.all(:preclosed_on_date.gte => @from_date, :preclosed_on_date.lte => @to_date, :status => :preclosed_loan_status).select{|pl| pl.borrower_town_classification == classification}.count        
      client_count_at_end_of_period = Lending.all(:applied_on_date.lte => @to_date).select{|cl| cl.borrower_town_classification == classification}.count

      data[:members_by_classification][classification] = {:classification_name => classification_name, :opening_balance => opening_balance, :new_loan_count_added_during_period => new_loan_count_added_during_period, :loan_closed_during_period => loan_closed_during_period, :loan_preclosed_during_period => loan_preclosed_during_period, :client_count_at_end_of_period => client_count_at_end_of_period}
    end

    #members by psl
    psl_master = PrioritySectorList.all.map{|psl| psl.id}
    psl_master_list = [nil] + psl_master
    psl_master_list.each do |psl|
      psl_name = (psl != nil) ? PrioritySectorList.get(psl).name : "Not Specified"
      opening_balance = Lending.all(:applied_on_date.lt => @from_date).select{|ob| ob.borrower_psl == psl}.count
      new_loan_count_added_during_period = Lending.all(:applied_on_date.gte => @from_date, :applied_on_date.lte => @to_date).select{|nl| nl.borrower_psl == psl}.count
      loan_closed_during_period = Lending.all(:repaid_on_date.gte => @from_date, :repaid_on_date.lte => @to_date, :status => :repaid_loan_status).select{|lc| lc.borrower_psl == psl}.count
      loan_preclosed_during_period = Lending.all(:preclosed_on_date.gte => @from_date, :preclosed_on_date.lte => @to_date, :status => :preclosed_loan_status).select{|lp| lp.borrower_psl == psl}.count        
      client_count_at_end_of_period = Lending.all(:applied_on_date.lte => @to_date).select{|cc| cc.borrower_psl == psl}.count

      data[:members_by_psl][psl] = {:psl_name => psl_name, :opening_balance => opening_balance, :new_loan_count_added_during_period => new_loan_count_added_during_period, :loan_closed_during_period => loan_closed_during_period, :loan_preclosed_during_period => loan_preclosed_during_period, :client_count_at_end_of_period => client_count_at_end_of_period}
    end

    return data
  end
end
