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
    data = {:members_by_caste => {}}

    #members by caste
    caste_master_list = Constants::Masters::CASTE_CHOICE
    caste_master_list.each do |caste|
      caste_name = caste.to_s.humanize
      opening_balance = Client.all(:date_joined.lt => @from_date, :caste => caste).count
      client_ids_created_in_date_range_per_caste = Client.all(:date_joined.gte => @from_date, :date_joined.lte => @to_date, :caste => caste).aggregate(:id)
      if client_ids_created_in_date_range_per_caste.empty?
        new_loan_count_added_during_period = loan_closed_during_period = loan_preclosed_during_period = 0
      else
        new_loan_count_added_during_period = Lending.all(:applied_on_date.gte => @from_date, :applied_on_date.lte => @to_date, :loan_borrower_id => client_ids_created_in_date_range_per_caste).count
        loan_closed_during_period = Lending.all(:repaid_on_date.gte => @from_date, :repaid_on_date.lte => @to_date, :status => :repaid_loan_status, :loan_borrower_id => client_ids_created_in_date_range_per_caste).count
        loan_preclosed_during_period = Lending.all(:preclosed_on_date.gte => @from_date, :preclosed_on_date.lte => @to_date, :status => :preclosed_loan_status, :loan_borrower_id => client_ids_created_in_date_range_per_caste).count        
      end
      client_count_at_end_of_period = Client.all(:date_joined.lte => @to_date, :caste => caste).count

      data[:members_by_caste][caste] = {:caste_name => caste_name, :opening_balance => opening_balance, :new_loan_count_added_during_period => new_loan_count_added_during_period, :loan_closed_during_period => loan_closed_during_period, :loan_preclosed_during_period => loan_preclosed_during_period, :client_count_at_end_of_period => client_count_at_end_of_period}
    end
    return data

  end
end
