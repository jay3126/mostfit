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
    loans = Lending.total_loans_between_dates('', @from_date, @to_date)
    new_loans = loans[LoanLifeCycle::LOAN_STATUSES.index(:new_loan_status)+1].blank? ? [] : loans[LoanLifeCycle::LOAN_STATUSES.index(:new_loan_status)+1].map(&:lending_id)
    disbursed_loans = loans[LoanLifeCycle::LOAN_STATUSES.index(:disbursed_loan_status)+1].blank? ? [] : loans[LoanLifeCycle::LOAN_STATUSES.index(:disbursed_loan_status)+1].map(&:lending_id)
    repay_loans = loans[LoanLifeCycle::LOAN_STATUSES.index(:repaid_loan_status)+1].blank? ? [] : loans[LoanLifeCycle::LOAN_STATUSES.index(:repaid_loan_status)+1].map(&:lending_id)
    preclouse_loans = loans[LoanLifeCycle::LOAN_STATUSES.index(:preclosed_loan_status)+1].blank? ? [] : loans[LoanLifeCycle::LOAN_STATUSES.index(:preclosed_loan_status)+1].map(&:lending_id)
    loan_clients       = Client.all(:fields => [:id, :caste, :religion, :town_classification, :priority_sector_list_id])

    #members by caste
    clients_caste_group = loan_clients.blank? ? {} : loan_clients.group_by{|c| c.caste}
    caste_master_list = Constants::Masters::CASTE_CHOICE
    caste_master_list.each do |caste|
      caste_name = caste.to_s.humanize
      clients    = clients_caste_group[caste].map(&:id) rescue []
      opening_balance = clients.blank? || disbursed_loans.blank? ? 0 : Lending.all(:id => disbursed_loans, 'loan_borrower.counterparty_id' => clients).count
      new_loans_added_during_period = clients.blank? || new_loans.blank? ? 0 : Lending.all(:id => new_loans, 'loan_borrower.counterparty_id' => clients).count
      loan_closed_during_period = clients.blank? || repay_loans.blank? ? 0 : Lending.all(:id => repay_loans, 'loan_borrower.counterparty_id' => clients).count
      loan_preclosed_during_period = clients.blank? || preclouse_loans.blank? ? 0 : Lending.all(:id => preclouse_loans, 'loan_borrower.counterparty_id' => clients).count
      client_count_at_end_of_period = opening_balance + new_loans_added_during_period + loan_closed_during_period + loan_preclosed_during_period

      data[:members_by_caste][caste] = {:caste_name => caste_name, :opening_balance => opening_balance, :new_loans_added_during_period => new_loans_added_during_period, :loan_closed_during_period => loan_closed_during_period, :loan_preclosed_during_period => loan_preclosed_during_period, :client_count_at_end_of_period => client_count_at_end_of_period}
    end

    #members by religion
    clients_religion_group = loan_clients.blank? ? {} : loan_clients.group_by{|c| c.religion}
    religion_master_list = Constants::Masters::RELIGION_CHOICE
    religion_master_list.each do |religion|
      religion_name = religion.to_s.humanize
      clients    = clients_religion_group[religion].map(&:id) rescue []
      opening_balance = clients.blank? || disbursed_loans.blank? ? 0 : Lending.all(:id => disbursed_loans, 'loan_borrower.counterparty_id' => clients).count
      new_loans_added_during_period = clients.blank? || new_loans.blank? ? 0 : Lending.all(:id => new_loans, 'loan_borrower.counterparty_id' => clients).count
      loan_closed_during_period = clients.blank? || repay_loans.blank? ? 0 : Lending.all(:id => repay_loans, 'loan_borrower.counterparty_id' => clients).count
      loan_preclosed_during_period = clients.blank? || preclouse_loans.blank? ? 0 : Lending.all(:id => preclouse_loans, 'loan_borrower.counterparty_id' => clients).count
      client_count_at_end_of_period = opening_balance + new_loans_added_during_period + loan_closed_during_period + loan_preclosed_during_period

      data[:members_by_religion][religion] = {:religion_name => religion_name, :opening_balance => opening_balance, :new_loan_count_added_during_period => new_loans_added_during_period  , :loan_closed_during_period => loan_closed_during_period, :loan_preclosed_during_period => loan_preclosed_during_period, :client_count_at_end_of_period => client_count_at_end_of_period}
    end

    #members by loan_cycle
    cycle_number_master = Lending.all.aggregate(:cycle_number)
    cycle_number_master.each do |loan_cycle_number|
      opening_balance = disbursed_loans.blank? ? 0 : Lending.all(:id => disbursed_loans, :cycle_number => loan_cycle_number).count
      new_loans_added_during_period = new_loans.blank? ? 0 : Lending.all(:id => new_loans, :cycle_number => loan_cycle_number).count
      loan_closed_during_period = repay_loans.blank? ? 0 : Lending.all(:id => repay_loans, :cycle_number => loan_cycle_number).count
      loan_preclosed_during_period = preclouse_loans.blank? ? 0 : Lending.all(:id => preclouse_loans, :cycle_number => loan_cycle_number).count
      client_count_at_end_of_period = opening_balance + new_loans_added_during_period + loan_closed_during_period + loan_preclosed_during_period

      data[:members_by_loan_cycle][loan_cycle_number] = {:cycle_number => loan_cycle_number, :opening_balance => opening_balance, :new_loan_count_added_during_period => new_loans_added_during_period, :loan_closed_during_period => loan_closed_during_period, :loan_preclosed_during_period => loan_preclosed_during_period, :client_count_at_end_of_period => client_count_at_end_of_period}
    end

    #members by loan_product
    loan_product_master = LendingProduct.all
    loan_product_master.each do |loan_product|
      opening_balance = disbursed_loans.blank? ? 0 : Lending.all(:id => disbursed_loans, :lending_product_id => loan_product.id).count
      new_loans_added_during_period = new_loans.blank? ? 0 : Lending.all(:id => new_loans, :lending_product_id => loan_product.id).count
      loan_closed_during_period = repay_loans.blank? ? 0 : Lending.all(:id => repay_loans, :lending_product_id => loan_product.id).count
      loan_preclosed_during_period = preclouse_loans.blank? ? 0 : Lending.all(:id => preclouse_loans, :lending_product_id => loan_product.id).count
      client_count_at_end_of_period = opening_balance + new_loans_added_during_period + loan_closed_during_period + loan_preclosed_during_period

      data[:members_by_loan_product][loan_product] = {:loan_product => loan_product.name, :opening_balance => opening_balance, :new_loan_count_added_during_period => new_loans_added_during_period, :loan_closed_during_period => loan_closed_during_period, :loan_preclosed_during_period => loan_preclosed_during_period, :client_count_at_end_of_period => client_count_at_end_of_period}
    end

    #members_by_branch
    branch_master = location_facade.all_nominal_branches
    branch_master.each do |branch|
      opening_balance = LoanAdministration.get_loan_ids_accounted_for_date_range_by_sql(branch.id, @from_date, @to_date, false, 'disbursed_loan_status').count
      new_loan_count_added_during_period = LoanAdministration.get_loan_ids_accounted_for_date_range_by_sql(branch.id, @from_date, @to_date, false, 'new_loan_status').count
      loan_closed_during_period = LoanAdministration.get_loan_ids_accounted_for_date_range_by_sql(branch.id, @from_date, @to_date, false, 'repaid_loan_status').count
      loan_preclosed_during_period = LoanAdministration.get_loan_ids_accounted_for_date_range_by_sql(branch.id, @from_date, @to_date, false, 'preclosed_loan_status').count
      client_count_at_end_of_period = opening_balance + new_loan_count_added_during_period + loan_closed_during_period + loan_preclosed_during_period

      data[:members_by_branch][branch] = {:branch_name => branch.name, :opening_balance => opening_balance, :new_loan_count_added_during_period => new_loan_count_added_during_period, :loan_closed_during_period => loan_closed_during_period, :loan_preclosed_during_period => loan_preclosed_during_period, :client_count_at_end_of_period => client_count_at_end_of_period}
    end

    #members by classification
    clients_classification_group = loan_clients.blank? ? {} : loan_clients.group_by{|c| c.town_classification}
    town_classification_master_list = Constants::Masters::TOWN_CLASSIFICATION
    town_classification_master_list.each do |classification|
      classification_name = classification.to_s.humanize
      clients             = clients_classification_group[classification].map(&:id) rescue []
      opening_balance = clients.blank? || disbursed_loans.blank? ? 0 : Lending.all(:id => disbursed_loans, 'loan_borrower.counterparty_id' => clients).count
      new_loans_added_during_period = clients.blank? || new_loans.blank? ? 0 : Lending.all(:id => new_loans, 'loan_borrower.counterparty_id' => clients).count
      loan_closed_during_period = clients.blank? || repay_loans.blank? ? 0 : Lending.all(:id => repay_loans, 'loan_borrower.counterparty_id' => clients).count
      loan_preclosed_during_period = clients.blank? || preclouse_loans.blank? ? 0 : Lending.all(:id => preclouse_loans, 'loan_borrower.counterparty_id' => clients).count
      client_count_at_end_of_period = opening_balance + new_loans_added_during_period + loan_closed_during_period + loan_preclosed_during_period

      data[:members_by_classification][classification] = {:classification_name => classification_name, :opening_balance => opening_balance, :new_loan_count_added_during_period => new_loans_added_during_period, :loan_closed_during_period => loan_closed_during_period, :loan_preclosed_during_period => loan_preclosed_during_period, :client_count_at_end_of_period => client_count_at_end_of_period}
    end

    #members by psl
    clients_psl_group = loan_clients.blank? ? {} : loan_clients.group_by{|c| c.priority_sector_list_id}
    psl_master = PrioritySectorList.all
    psl_master_list = [nil] + psl_master
    psl_master_list.each do |psl|
      psl_name = (psl != nil) ? psl.name : "Not Specified"
      clients  = (psl != nil) ? clients_psl_group[psl.id] : clients_psl_group[nil]
      clients  = clients.blank? ? [] : clients.map(&:id)
      opening_balance = clients.blank? || disbursed_loans.blank? ? 0 : Lending.all(:id => disbursed_loans, 'loan_borrower.counterparty_id' => clients).count
      new_loans_added_during_period = clients.blank? || new_loans.blank? ? 0 : Lending.all(:id => new_loans, 'loan_borrower.counterparty_id' => clients).count
      loan_closed_during_period = clients.blank? || repay_loans.blank? ? 0 : Lending.all(:id => repay_loans, 'loan_borrower.counterparty_id' => clients).count
      loan_preclosed_during_period = clients.blank? || preclouse_loans.blank? ? 0 : Lending.all(:id => preclouse_loans, 'loan_borrower.counterparty_id' => clients).count
      client_count_at_end_of_period = opening_balance + new_loans_added_during_period + loan_closed_during_period + loan_preclosed_during_period

      data[:members_by_psl][psl] = {:psl_name => psl_name, :opening_balance => opening_balance, :new_loan_count_added_during_period => new_loans_added_during_period, :loan_closed_during_period => loan_closed_during_period, :loan_preclosed_during_period => loan_preclosed_during_period, :client_count_at_end_of_period => client_count_at_end_of_period}
    end

    return data
  end
end
