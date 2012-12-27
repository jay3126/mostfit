class IncomeCashflowProjectionReport < Report

  attr_accessor :from_date, :to_date, :page

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 30
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Income Cashflow Projection Report from #{@from_date} to #{@to_date}"
    @user = user
    location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, @user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch] and (not (params[:biz_location_branch].empty?))) ? params[:biz_location_branch] : all_branch_ids
    @page = params.blank? || params[:page].blank? ? 1 : params[:page]
    @limit = 10
    get_parameters(params, user)
  end

  def name
    "Income Cashflow Projection Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Income Cashflow Projection Report"
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate
    data = {}

    params = {:status => :disbursed_loan_status}
    loan_ids = Lending.all(params).to_a.paginate(:page => @page, :per_page => @limit)
    data[:loan_ids] = loan_ids
    data[:loans] = {}
    loan_ids.each do |loan|
      month = @from_date.strftime("%B")
      year = @from_date.strftime("%Y")
      loan_id = loan.id
      loan_disbursal_date = loan.disbursal_date
      projected_pos_at_monthend = loan.scheduled_principal_outstanding(@to_date)

      if loan.principal_received_till_date(@from_date) > loan.principal_received_till_date(@to_date)
        schedule_principal_realisations = loan.principal_received_till_date(@from_date) - loan.principal_received_till_date(@to_date)
      else
        schedule_principal_realisations = loan.principal_received_till_date(@to_date) - loan.principal_received_till_date(@from_date)
      end

      if loan.interest_received_till_date(@from_date) > loan.interest_received_till_date(@to_date)
        schedule_interest_realisations = loan.interest_received_till_date(@from_date) - loan.interest_received_till_date(@to_date)
      else
        schedule_interest_realisations = loan.interest_received_till_date(@to_date) - loan.interest_received_till_date(@from_date)
      end

      schedule_total_realisations = schedule_principal_realisations + schedule_interest_realisations
      projected_interest_accrual = loan.accrued_interim_interest(@from_date, @to_date)

      data[:loans][loan] = {:month => month, :year => year, :projected_pos_at_monthend => projected_pos_at_monthend, :schedule_principal_realisations => schedule_principal_realisations, :schedule_interest_realisations => schedule_interest_realisations, :schedule_total_realisations => schedule_total_realisations, :projected_interest_accrual => projected_interest_accrual, :loan_id => loan_id, :loan_disbursal_date => loan_disbursal_date}
    end
    data
  end
end