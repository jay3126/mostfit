class LoanCollectionsDetailReport < Report

  attr_accessor :biz_location_branch_id, :date

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Loan Collections Detail Report on #{@date}"
    @user = user
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : []
    get_parameters(params, user)
  end

  def name
    "Loan Collections Detail Report on #{@date}"
  end

  def self.name
    "Loan Collections Detail Report"
  end

  def get_reporting_facade(user)
    @reporting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, user)
  end

  def get_location_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user)
  end

  def generate

    data = {}
    location_facade = get_location_facade(@user)
    reporting_facade = get_reporting_facade(@user)
    location = @biz_location_branch.blank? ? nil : BizLocation.get(@biz_location_branch)
    all_center_ids_array = @biz_location_branch.blank? ? [] : LocationLink.all_children_by_sql(location, @date)
    all_center_ids_array.flatten.each do |center|
      center_id = center.id
      center_name = center ? center.name : "Not Specified"
      branch = location
      branch_name = branch ? branch.name : "Not Specified"
      dues_collected_and_collectable = reporting_facade.total_schedule_collected_and_collectable_per_center_on_date(center_id, @date)
      receipt_number = "Not Specified"
      staff_name = dues_collected_and_collectable[:managed_by_staff]
      data[staff_name] = [] if data[staff_name].blank?
      if dues_collected_and_collectable[:scheduled_total] > MoneyManager.default_zero_money
        data[staff_name] << {:staff_name => staff_name, :branch_name => branch_name, :center_name => center_name, :dues_collected_and_collectable => dues_collected_and_collectable, :receipt_number => receipt_number}
      end
    end
    data
  end
end
