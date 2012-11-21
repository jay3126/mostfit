class CenterList < Report

  attr_accessor :biz_location_branch_id, :date

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Center List on #{@date}"
    @user = user
    @biz_location_branch = params[:biz_location_branch_id] rescue nil
    get_parameters(params, user)
  end

  def name
    "Center List on #{@date}"
  end

  def self.name
    "Center List"
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
    location_manage.blank? ? 'Not Managed' : location_manage.manager_staff_member.name
  end

  def generate
    data = {}
    location_facade = get_location_facade(@user)
    meeting_facade = get_meeting_facade(@user)
    all_centers = @biz_location_branch.blank? ? location_facade.all_nominal_centers : LocationLink.all_children_by_sql(BizLocation.get(@biz_location_branch), @date)

    all_centers.each do |center|
      branch = location_facade.get_parent(BizLocation.get(center.id), @date)
      branch_name = branch ? branch.name : "Not Specified"
      branch_id = branch ? branch.id : "Not Specified"
      agent_name = managed_by_staff(center.id, @date)
      center_name = center.name
      center_id = center.id
      meetings = meeting_facade.get_meeting_schedules(center).first
      meeting_day = (meetings and meetings.schedule_begins_on) ? meetings.schedule_begins_on.strftime("%A") : "Not Specified"
      meeting_time = meetings ? meetings.meeting_begins_at : "Not Specified"
      meeting_frequency = meetings ? meetings.meeting_frequency : "Not Specified"
      center_disbursal_date = (center and center.center_disbursal_date) ? center.center_disbursal_date : "Not Specified"

      data[center.name] = {:branch_id => branch_id, :branch_name => branch_name, :agent_name => agent_name, :center_id => center_id, :center_name => center_name, :meeting_day => meeting_day, :meeting_time => meeting_time, :meeting_frequency => meeting_frequency, :center_disbursal_date => center_disbursal_date}
    end
    data
  end
  
end