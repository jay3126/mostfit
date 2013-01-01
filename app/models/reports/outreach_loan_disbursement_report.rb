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
    disbursed_loan_ids = Lending.total_loans_between_dates('disbursed_loan_status', @from_date, @to_date)
    disbursed_loans    = disbursed_loan_ids.blank? ? [] : Lending.all( :fields => [:id, :lending_product_id, :disbursed_amount, :cycle_number], :id => disbursed_loan_ids)
    loan_receipts      = LoanReceipt.between_receipts(disbursed_loan_ids,  @from_date, @to_date)
    loan_clients       = Client.all(:fields => [:id, :caste, :religion, :town_classification, :priority_sector_list_id])
    #loan_disbursement_by_caste
    clients_caste_group = loan_clients.blank? ? {} : loan_clients.group_by{|c| c.caste}
    caste_master_list = Constants::Masters::CASTE_CHOICE
    caste_master_list.each do |caste|
      caste_name           = caste.to_s.humanize
      client_ids           = clients_caste_group[caste].map(&:id) rescue []
      loan_ids             = client_ids.blank? ? [] : Lending.all('loan_borrower.counterparty_id' => client_ids, :id => disbursed_loan_ids).aggregate(:id)
      disbursed_amt        = loan_ids.blank? ? 0 : Lending.all(:id => loan_ids).aggregate(:disbursed_amount.sum)
      receipts             = loan_ids.blank? || loan_receipts.blank? ? [] : loan_receipts.select{|r| loan_ids.include?(r.lending_id)}
      loan_receipt         = LoanReceipt.add_up(receipts)
      disbursed_amount     = loan_ids.blank? ? MoneyManager.default_zero_money : Money.new(disbursed_amt.to_i, default_currency)
      total_pos_per_caste  = disbursed_amount > loan_receipt[:principal_received] ? disbursed_amount-loan_receipt[:principal_received] : MoneyManager.default_zero_money
      data[:loan_disbursement_by_caste][caste] = {:caste_name => caste_name, :total_pos_per_caste => total_pos_per_caste, :disbursed_loan_count => loan_ids.size}
    end

    clients_religion_group = loan_clients.blank? ? {} : loan_clients.group_by{|c| c.religion}
    #loan_disbursement_by_religion
    religion_master_list = Constants::Masters::RELIGION_CHOICE
    religion_master_list.each do |religion|
      religion_name        = religion.to_s.humanize
      client_ids           = clients_religion_group[religion].map(&:id) rescue []
      loan_ids             = client_ids.blank? ? [] : Lending.all('loan_borrower.counterparty_id' => client_ids, :id => disbursed_loan_ids).aggregate(:id)
      disbursed_amt        = loan_ids.blank? ? 0 : Lending.all(:id => loan_ids).aggregate(:disbursed_amount.sum)
      receipts             = loan_ids.blank? || loan_receipts.blank? ? [] : loan_receipts.select{|r| loan_ids.include?(r.lending_id)}
      loan_receipt         = LoanReceipt.add_up(receipts)
      disbursed_amount     = loan_ids.blank? ? MoneyManager.default_zero_money : Money.new(disbursed_amt.to_i, default_currency)
      total_pos_per_religion  = disbursed_amount > loan_receipt[:principal_received] ? disbursed_amount-loan_receipt[:principal_received] : MoneyManager.default_zero_money
      data[:loan_disbursement_by_religion][religion] = {:religion_name => religion_name, :total_pos_per_religion => total_pos_per_religion, :disbursed_loan_count => loan_ids.size}
    end

    #loan disbursement by loan cycle.
    loans_group_by_cycle_number = disbursed_loans.group_by{|l| l.cycle_number}
    cycle_number_master = Lending.all.aggregate(:cycle_number)
    cycle_number_master.each do |loan_cycle_number|
      loans                  = loans_group_by_cycle_number[loan_cycle_number]
      loan_ids               = loans.blank? ? [] : loans.map(&:id)
      disbursed_amt          = loans.blank? ? 0 : loans.map(&:disbursed_amount).sum
      total_amount_disbursed = loan_ids.blank? ? MoneyManager.default_zero_money : Money.new(disbursed_amt.to_i, default_currency)
      data[:loan_disbursement_by_loan_cycle][loan_cycle_number] = {:cycle_number => loan_cycle_number, :disbursed_loan_count => loan_ids.size, :total_amount_disbursed => total_amount_disbursed}
    end

    #loan_disbursement_by_loan_product
    loans_group_by_loan_product = disbursed_loans.group_by{|l| l.lending_product_id}
    loan_product_master_list = LendingProduct.all
    loan_product_master_list.each do |loan_product|
      loans                      = loans_group_by_loan_product[loan_product.id]
      loan_ids                   = loans.blank? ? [] : loans.map(&:id)
      disbursed_amt              = loans.blank? ? 0 : loans.map(&:disbursed_amount).sum
      receipts                   = loan_ids.blank? || loan_receipts.blank? ? [] : loan_receipts.select{|r| loan_ids.include?(r.lending_id)}
      loan_receipt               = LoanReceipt.add_up(receipts)
      disbursed_amount           = loan_ids.blank? ? MoneyManager.default_zero_money : Money.new(disbursed_amt.to_i, default_currency)
      total_pos_per_loan_product = disbursed_amount > loan_receipt[:principal_received] ? disbursed_amount-loan_receipt[:principal_received] : MoneyManager.default_zero_money
      data[:loan_disbursement_by_loan_product][loan_product] = {:loan_product_name => loan_product.name, :total_pos_per_loan_product => total_pos_per_loan_product, :disbursed_loan_count => loan_ids.size}
    end

    #loan_disbursement_by_branch
    branch_master_list = location_facade.all_nominal_branches
    branch_master_list.each do |branch|
      loan_ids             = LoanAdministration.get_loan_ids_accounted_for_date_range_by_sql(branch.id, @from_date, @to_date, false, 'disbursed_loan_status')
      loan_disbursed_amt   = loan_ids.blank? ? 0 : Lending.all(:id => loan_ids).aggregate(:disbursed_amount.sum)
      receipts             = loan_ids.blank? || loan_receipts.blank? ? [] : loan_receipts.select{|r| loan_ids.include?(r.lending_id)}
      loan_receipt         = LoanReceipt.add_up(receipts)
      disbursed_amount     = loan_ids.blank? ? MoneyManager.default_zero_money : Money.new(loan_disbursed_amt.to_i, default_currency)
      total_pos_per_branch = disbursed_amount > loan_receipt[:principal_received] ? disbursed_amount-loan_receipt[:principal_received] : MoneyManager.default_zero_money
      data[:loan_disbursement_by_branch][branch] = {:branch_name => branch.name, :total_pos_per_branch => total_pos_per_branch, :disbursed_loan_count => loan_ids.size}
    end

    clients_classification_group = loan_clients.blank? ? {} : loan_clients.group_by{|c| c.town_classification}
    #loan_disbursement_by_classification
    town_classification_master_list = Constants::Masters::TOWN_CLASSIFICATION
    town_classification_master_list.each do |classification|
      classification_name = classification.to_s.humanize
      clients              = clients_classification_group[classification]
      loan_ids             = clients.blank? ? [] : Lending.all('loan_borrower.counterparty_id' => clients.map(&:id), :id => disbursed_loan_ids).aggregate(:id)
      disbursed_amt        = loan_ids.blank? ? 0 : Lending.all(:id => loan_ids).aggregate(:disbursed_amount.sum)
      receipts             = loan_ids.blank? || loan_receipts.blank? ? [] : loan_receipts.select{|r| loan_ids.include?(r.lending_id)}
      loan_receipt         = LoanReceipt.add_up(receipts)
      disbursed_amount     = loan_ids.blank? ? MoneyManager.default_zero_money : Money.new(disbursed_amt.to_i, default_currency)
      total_pos_per_classification = disbursed_amount > loan_receipt[:principal_received] ? disbursed_amount-loan_receipt[:principal_received] : MoneyManager.default_zero_money
      data[:loan_disbursement_by_classification][classification] = {:classification_name => classification_name, :total_pos_per_classification => total_pos_per_classification, :disbursed_loan_count => loan_ids.size}
    end

    clients_psl_group = loan_clients.blank? ? {} : loan_clients.group_by{|c| c.priority_sector_list_id}
    #loan_disbursement_by_psl
    psl_master = PrioritySectorList.all
    psl_master_list = [nil] + psl_master
    psl_master_list.each do |psl|
      psl_name             = (psl != nil) ? psl.name : "Not Specified"
      clients              = (psl != nil) ? clients_psl_group[psl.id] : clients_psl_group[nil]
      loan_ids             = clients.blank? ? [] : Lending.all('loan_borrower.counterparty_id' => clients.map(&:id), :id => disbursed_loan_ids).aggregate(:id)
      disbursed_amt        = loan_ids.blank? ? 0 : Lending.all(:id => loan_ids).aggregate(:disbursed_amount.sum)
      receipts             = loan_ids.blank? || loan_receipts.blank? ? [] : loan_receipts.select{|r| loan_ids.include?(r.lending_id)}
      loan_receipt         = LoanReceipt.add_up(receipts)
      disbursed_amount     = loan_ids.blank? ? MoneyManager.default_zero_money : Money.new(disbursed_amt.to_i, default_currency)
      total_pos_per_psl    = disbursed_amount > loan_receipt[:principal_received] ? disbursed_amount-loan_receipt[:principal_received] : MoneyManager.default_zero_money
      data[:loan_disbursement_by_psl][psl] = {:psl_name => psl_name, :total_pos_per_psl => total_pos_per_psl, :disbursed_loan_count => loan_ids.size}
    end
    
    return data
  end
end
