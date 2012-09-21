class CashOutFlow < Report

  attr_accessor :from_date, :to_date, :biz_location_branch

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Cash Outflow from #{@from_date} to #{@to_date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch] and (not (params[:biz_location_branch].empty?))) ? params[:biz_location_branch] : all_branch_ids
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

    reporting_facade = get_reporting_facade(@user)
    location_facade  = get_location_facade(@user)
    data = {}
    
    if @biz_location_branch.class == Fixnum
      all_centers = location_facade.get_children(BizLocation.get(@biz_location_branch), @to_date)
    else
      all_centers = location_facade.all_nominal_centers
    end

    all_centers.each do |center|
      center_name = center.name
      branch = location_facade.get_parent(BizLocation.get(center.id), @to_date)
      branch_name = branch ? branch.name : "Not Specified"
      branch_id = branch ? branch.id : "Not Specified"
      location = LocationLink.all_parents(center, @to_date)
      district = location.select{|s| s.location_level.name.downcase == 'district'}.first
      district_name = (district and (not district.blank?)) ? district.name : "Not Specified"
      #center_count = location_facade.get_children(branch, @to_date).count
      loan_amount  = reporting_facade.sum_all_loan_amounts_per_center_for_a_date_range(@from_date, @to_date, center.id)
      disbursal_date = (center and center.center_disbursal_date) ? center.center_disbursal_date : "Not Specified"

      data[center] = {:branch_name => branch_name, :district_name => district_name, :disbursal_date => disbursal_date, :center_name => center_name, :loan_amount => loan_amount}
    end
    data
  end
end
