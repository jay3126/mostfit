class OutreachCenterGroupCountReport < Report

  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Outreach Center Group Count Report from #{@from_date} to #{@to_date}"
    @user = user
    get_parameters(params, user)
  end

  def name
    "Outreach Center Group Count Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Outreach Center Group Count Report"
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
    data = {}

    centers_created_in_date_range = BizLocation.all("location_level.level" => 0, :center_disbursal_date.gte => @from_date, :center_disbursal_date.lte => @to_date).count
    centers_count_at_beginning_of_date_range = BizLocation.all("location_level.level" => 0, :center_disbursal_date.lt => @from_date).count
    centers_closed_during_date_range = 0
    centers_count_at_end_of_date_range = BizLocation.all("location_level.level" => 0, :center_disbursal_date.lte => @to_date).count

    client_groups_created_in_date_range = ClientGroup.all(:creation_date.gte => @from_date, :creation_date.lte => @to_date).count
    client_groups_count_at_beginning_of_date_range = ClientGroup.all(:creation_date.lt => @from_date).count
    client_groups_closed_during_date_range = 0
    client_groups_count_at_end_of_date_range = ClientGroup.all(:creation_date.lte => @to_date).count

    client_created_in_date_range = Lending.all(:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date, :status => LoanLifeCycle::DISBURSED_LOAN_STATUS).count
    loan_matured_in_date_range = Lending.all(:repaid_on_date.gte => @from_date, :repaid_on_date=> @to_date, :status => LoanLifeCycle::REPAID_LOAN_STATUS).count
    loan_preclosure_in_date_range = Lending.all(:preclosed_on_date.gte => @from_date, :preclosed_on_date => @to_date, :status => LoanLifeCycle::PRECLOSED_LOAN_STATUS).count
    all_clients_count = Client.all.count
    female_clients_count = Client.all(:gender => Constants::Masters::FEMALE_GENDER).count

    data = {:all_clients_count => all_clients_count, :female_clients_count => female_clients_count, :client_created_in_date_range =>  client_created_in_date_range, :loan_matured_in_date_range => loan_matured_in_date_range, :loan_preclosure_in_date_range => loan_preclosure_in_date_range, :centers_created_in_date_range => centers_created_in_date_range, :centers_count_at_beginning_of_date_range => centers_count_at_beginning_of_date_range, :centers_closed_during_date_range => centers_closed_during_date_range, :centers_count_at_end_of_date_range => centers_count_at_end_of_date_range, :client_groups_created_in_date_range => client_groups_created_in_date_range, :client_groups_count_at_beginning_of_date_range => client_groups_count_at_beginning_of_date_range, :client_groups_closed_during_date_range => client_groups_closed_during_date_range, :client_groups_count_at_end_of_date_range => client_groups_count_at_end_of_date_range}
    return data
  end
end
