class CashOutFlow < Report

  attr_accessor :from_date, :to_date, :biz_location_branch_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Cash Outflow from #{@from_date} to #{@to_date}"
    @user = user
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : []
    @page = params.blank? || params[:page].blank? ? 1 :params[:page]
    @limit = 10
    get_parameters(params, user)
  end

  def name
    "Cash Outflow from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Cash Outflow Report"
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
    if @biz_location_branch.blank?
      disbursed_loan_ids = Lending.total_loans_between_dates('disbursed_loan_status', @from_date, @to_date)
      disbursal_loans = disbursed_loan_ids.blank? ? [] : Lending.all(:fields => [:id, :disbursed_amount, :disbursal_date, :accounted_at_origin, :administered_at_origin], :id => disbursed_loan_ids, :disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date)
    else
      disbursed_loan_ids = LoanAdministration.get_loan_ids_accounted_for_date_range_by_sql(@biz_location_branch, @from_date, @to_date, false, 'disbursed_loan_status')
      disbursal_loans = disbursed_loan_ids.blank? ? [] : Lending.all(:fields => [:id, :disbursed_amount, :disbursal_date, :accounted_at_origin, :administered_at_origin], :id => disbursed_loan_ids, :disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date)
    end

    disbursal_loans.group_by{|lb| lb.accounted_at_origin}.each do |branch_id, b_loans|
      data[branch_id] = {}
      branch = BizLocation.get branch_id
      branch_name = branch.name
      location = LocationLink.all_parents(branch, @to_date)
      district = location.select{|s| s.location_level.name.downcase == 'district'}.first
      district_name = (district and (not district.blank?)) ? district.name : "Not Specified"

      b_loans.group_by{|lc| lc.administered_at_origin}.each do |center_id, c_loans|
        data[branch_id][center_id] = {}
        center = BizLocation.get center_id
        center_name = center.name
        c_loans.group_by{|dl| dl.disbursal_date}.each do |d_date, d_loans|
          data[branch_id][center_id][d_date] = {}
          disbursed_amt = d_loans.map(&:disbursed_amount).sum
          disbursed_money_amt = MoneyManager.get_money_instance_least_terms(disbursed_amt.to_i)
          data[branch_id][center_id][d_date] = {:branch_name => branch_name, :district_name => district_name, :disbursal_date => d_date, :center_name => center_name, :disbursed_amount => disbursed_money_amt}
        end
      end
    end
    data
  end
end
