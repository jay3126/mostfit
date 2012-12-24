class OutreachLoanDisbursementReport < Report

  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 30
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Outreach Loan Disbursement Report from #{@from_date} to #{@to_date}"
    @user = user
    get_parameters(params, user)
  end

  def name
    "Outreach Loan Disbursement Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Outreach Loan Disbursement Report"
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
    data = {:loan_disbursement_by_caste => {}, :loan_disbursement_by_religion => {}, :loan_disbursement_by_loan_cycle => {}, :loan_disbursement_by_loan_product => {}, :loan_disbursement_by_branch => {}, :loan_disbursement_by_classification => {}, :loan_disbursement_by_psl => {}}

    #loan_disbursement_by_caste
    caste_master_list = Constants::Masters::CASTE_CHOICE
    caste_master_list.each do |caste|
      caste_name = caste.to_s.humanize
      loans_disbursed_during_period_per_caste = Lending.all(:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date).select{|ld| ld.borrower_caste == caste}
      total_pos_per_caste = MoneyManager.default_zero_money
      disbursed_loan_count = loans_disbursed_during_period_per_caste.count
      loans_disbursed_during_period_per_caste.each do |loan|
        total_pos_per_caste += loan.actual_principal_outstanding(@to_date)
      end
      data[:loan_disbursement_by_caste][caste] = {:caste_name => caste_name, :total_pos_per_caste => total_pos_per_caste, :disbursed_loan_count => disbursed_loan_count}
    end

    #loan_disbursement_by_religion
    religion_master_list = Constants::Masters::RELIGION_CHOICE
    religion_master_list.each do |religion|
      religion_name = religion.to_s.humanize
      total_pos_per_religion = MoneyManager.default_zero_money      
      loans_disbursed_during_period_per_religion = Lending.all(:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date).select{|ld| ld.borrower_religion == religion}
      disbursed_loan_count = loans_disbursed_during_period_per_religion.count
      loans_disbursed_during_period_per_religion.each do |loan|
        total_pos_per_religion += loan.actual_principal_outstanding(@to_date)
      end
      data[:loan_disbursement_by_religion][religion] = {:religion_name => religion_name, :total_pos_per_religion => total_pos_per_religion, :disbursed_loan_count => disbursed_loan_count}
    end

    #loan disbursement by loan cycle.
    cycle_number_master = Lending.all.aggregate(:cycle_number)
    cycle_number_master.each do |loan_cycle_number|
      loans_disbursed_during_period_per_loan_cycle = Lending.all(:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date, :cycle_number => loan_cycle_number)
      disbursed_loan_count = loans_disbursed_during_period_per_loan_cycle.count
      total_amount_disbursed = MoneyManager.get_money_instance(Money.new(loans_disbursed_during_period_per_loan_cycle.aggregate(:disbursed_amount.sum).to_i, :INR).to_s)

      data[:loan_disbursement_by_loan_cycle][loan_cycle_number] = {:cycle_number => loan_cycle_number, :disbursed_loan_count => disbursed_loan_count, :total_amount_disbursed => total_amount_disbursed}
    end

    #loan_disbursement_by_loan_product
    loan_product_master_list = LendingProduct.all
    loan_product_master_list.each do |loan_product|
      loans_disbursed_during_period_per_loan_product = Lending.all(:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date, :lending_product_id => loan_product.id)
      total_pos_per_loan_product = MoneyManager.default_zero_money
      disbursed_loan_count = loans_disbursed_during_period_per_loan_product.count
      loans_disbursed_during_period_per_loan_product.each do |loan|
        total_pos_per_loan_product += loan.actual_principal_outstanding(@to_date)
      end
      data[:loan_disbursement_by_loan_product][loan_product] = {:loan_product_name => loan_product.name, :total_pos_per_loan_product => total_pos_per_loan_product, :disbursed_loan_count => disbursed_loan_count}
    end

    #loan_disbursement_by_branch
    branch_master_list = location_facade.all_nominal_branches
    branch_master_list.each do |branch|
      loans_disbursed_during_period_per_branch = Lending.all(:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date, :accounted_at_origin => branch.id)
      total_pos_per_branch = MoneyManager.default_zero_money
      disbursed_loan_count = loans_disbursed_during_period_per_branch.count
      loans_disbursed_during_period_per_branch.each do |loan|
        total_pos_per_branch += loan.actual_principal_outstanding(@to_date)
      end
      data[:loan_disbursement_by_branch][branch] = {:branch_name => branch.name, :total_pos_per_branch => total_pos_per_branch, :disbursed_loan_count => disbursed_loan_count}
    end

    #loan_disbursement_by_classification
    town_classification_master_list = Constants::Masters::TOWN_CLASSIFICATION
    town_classification_master_list.each do |classification|
      classification_name = classification.to_s.humanize
      loans_disbursed_during_period_per_classification = Lending.all(:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date).select{|ld| ld.borrower_town_classification == classification}
      total_pos_per_classification = MoneyManager.default_zero_money
      disbursed_loan_count = loans_disbursed_during_period_per_classification.count
      loans_disbursed_during_period_per_classification.each do |loan|
        total_pos_per_classification += loan.actual_principal_outstanding(@to_date)
      end
      data[:loan_disbursement_by_classification][classification] = {:classification_name => classification_name, :total_pos_per_classification => total_pos_per_classification, :disbursed_loan_count => disbursed_loan_count}
    end

    #loan_disbursement_by_psl
    psl_master = PrioritySectorList.all.map{|psl| psl.id}
    psl_master_list = [nil] + psl_master
    psl_master_list.each do |psl|
      psl_name = (psl != nil) ? PrioritySectorList.get(psl).name : "Not Specified"
      loans_disbursed_during_period_per_psl = Lending.all(:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date).select{|ld| ld.borrower_psl == psl}
      total_pos_per_psl = MoneyManager.default_zero_money
      disbursed_loan_count = loans_disbursed_during_period_per_psl.count
      loans_disbursed_during_period_per_psl.each do |loan|
        total_pos_per_psl += loan.actual_principal_outstanding(@to_date)
      end
      data[:loan_disbursement_by_psl][psl] = {:psl_name => psl_name, :total_pos_per_psl => total_pos_per_psl, :disbursed_loan_count => disbursed_loan_count}
    end
    
    return data
  end
end
