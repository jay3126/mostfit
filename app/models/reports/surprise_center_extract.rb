class SurpriseCenterExtract < Report

  attr_accessor :date, :biz_location_branch_id

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Surprise Center Extract Report for #{@date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : all_branch_ids
    get_parameters(params, user)
  end

  def name
    "Surprise Center Extract Report for #{@date}"
  end

  def self.name
    "Surprise Center Extract"
  end

  def get_reporting_facade(user)
    @reporting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, user)
  end

  def get_location_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user)
  end

  def get_meeting_facade(user)
    @meeting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, user)
  end

  def managed_by_staff(location_id, on_date)
    location_facade = get_location_facade(@user)
    location_manage = location_facade.location_managed_by_staff(location_id, on_date)
    if location_manage.blank?
      'Not Managed'
    else
      staff_member = location_manage.manager_staff_member
    end
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate

    data = {}
    reporting_facade = get_reporting_facade(@user)
    location_facade  = get_location_facade(@user)
    meeting_facade = get_meeting_facade(@user)

    if @biz_location_branch.class == Array
      all_centers = location_facade.all_nominal_centers
    else
      all_centers = location_facade.get_children(BizLocation.get(@biz_location_branch), @date)
    end

    all_centers.each do |center|
      branch = location_facade.get_parent(BizLocation.get(center.id), @date)
      branch_name = branch ? branch.name : "Not Specified"
      branch_id = branch ? branch.id : "Not Specified"
      center_id = center.id
      center_name = center.name
      center_creation_month = (center and center.creation_date) ? center.creation_date.strftime("%B") : "Not Specified"
      center_creation_year = (center and center.creation_date) ? center.creation_date.strftime("%Y") : "Not Specified"
      ro = managed_by_staff(center.id, @date)      
      if ro == "Not Managed"
        ro_name = "Not Managed"
        ro_code = "Not Available"
      else
        ro_name = ro.name
        ro_code = (ro and ro.employee_id and not (ro.employee_id.blank?)) ? ro.employee_id : "Not Available"
      end
      meeting = meeting_facade.get_meeting_schedules(center).first
      meeting_day = (meeting and meeting.schedule_begins_on) ? meeting.schedule_begins_on.strftime("%A") : "Not Specified"
      meeting_time = meeting ? meeting.meeting_begins_at : "Not Specified"
      loan_start_date = "Not Specified"
      loan_cycle = "Not Specified"

      data[center] = {:branch_name => branch_name, :branch_id => branch_id, :center_id => center_id, :center_name => center_name, :center_creation_month => center_creation_month, :center_creation_year => center_creation_year, :ro_name => ro_name, :ro_code => ro_code, :meeting_day => meeting_day, :meeting_time => meeting_time, :loan_start_date => loan_start_date, :loan_cycle => loan_cycle}
    end
    data    
  end
end