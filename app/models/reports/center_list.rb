class CenterList < Report

  attr_accessor :biz_location_branch_id, :date, :page

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Center List on #{@date}"
    @user = user
    @biz_location_branch = params[:biz_location_branch_id] rescue nil
    @page = params.blank? || params[:page].blank? ? 1 : params[:page]
    @limit = 10
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

  def managed_by_staff(location_id, on_date)
    location_facade = get_location_facade(@user)
    location_manage = location_facade.location_managed_by_staff(location_id, on_date)
    location_manage.blank? ? 'Not Managed' : location_manage.manager_staff_member.name
  end

  def generate
    data = {}
    location_facade = get_location_facade(@user)
    biz_location = BizLocation.get(@biz_location_branch) unless @biz_location_branch.blank?
    all_centers = @biz_location_branch.blank? ? location_facade.all_nominal_centers.to_a.paginate(:page => @page, :per_page => @limit) : LocationLink.all_children_by_sql(biz_location, @date).to_a.paginate(:page => @page, :per_page => @limit)
    data[:center_ids] = all_centers
    data[:centers] = {}

    all_centers.each do |center|
      branch = @biz_location_branch.blank? ? location_facade.get_parent(BizLocation.get(center.id), @date) : biz_location
      branch_name = branch ? branch.name : "Not Specified"
      branch_id = branch ? branch.biz_location_identifier : "Not Specified"
      agent_name = managed_by_staff(center.id, @date)
      center_name = center.name
      center_id = center.biz_location_identifier
      meetings = MeetingScheduleManager.get_all_meeting_schedule_infos(center).first
      meeting_dates = MeetingCalendar.next_meeting_for_location(center, @date)
      meeting_date = (meeting_dates and !meeting_dates.blank?) ? meeting_dates : "Not Specified"
      meeting_time = meetings ? meetings.meeting_begins_at : "Not Specified"
      meeting_frequency = meetings ? meetings.meeting_frequency : "Not Specified"
      center_disbursal_date = (center and center.center_disbursal_date) ? center.center_disbursal_date : "Not Specified"

      data[:centers][center.name] = {:branch_id => branch_id, :branch_name => branch_name, :agent_name => agent_name, :center_id => center_id,
        :center_name => center_name, :meeting_date => meeting_date, :meeting_time => meeting_time, :meeting_frequency => meeting_frequency,
        :center_disbursal_date => center_disbursal_date}
    end
    data
  end 
  
end
