class SurpriseCenterExtract < Report

  attr_accessor :from_date, :to_date, :page

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 30
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Surprise Center Extract Report from #{@from_date} to #{@to_date}"
    @user = user
    location_facade = get_location_facade(@user)
    @page = params.blank? || params[:page].blank? ? 1 :params[:page]
    @limit = 50
    get_parameters(params, user)
  end

  def name
    "Surprise Center Extract Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Surprise Center Extract"
  end

  def get_location_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user)
  end

  def managed_by_staff(location_id)
    location_facade = get_location_facade(@user)
    location_manage = location_facade.location_managed_by_staff(location_id)
    if location_manage.blank?
      'Not Managed'
    else
      location_manage.manager_staff_member
    end
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate

    data = {}
    location_facade  = get_location_facade(@user)

    meeting_center_ids = MeetingCalendar.all_locations_meeting_in_date_range(@from_date, @to_date, Constants::Space::PROPOSED_MEETING_STATUS).first[1].paginate(:page => @page, :per_page => @limit)
    data[:center_ids] = meeting_center_ids
    data[:centers] = {}
    meeting_center_ids.each do |center_id|
      center = BizLocation.get(center_id)
      branch = location_facade.get_parent(BizLocation.get(center.id))
      branch_name = branch ? branch.name : "Not Specified"
      branch_id = branch ? branch.id : "Not Specified"
      center_id = center.id
      center_name = center.name
      center_creation_month = (center && center.creation_date) ? center.creation_date.strftime("%B") : "Not Specified"
      center_creation_year = (center && center.creation_date) ? center.creation_date.strftime("%Y") : "Not Specified"
      ro = managed_by_staff(center.id)
      if ro == "Not Managed"
        ro_name = "Not Managed"
        ro_code = "Not Available"
      else
        ro_name = ro.name
        ro_code = (ro && ro.employee_id && !(ro.employee_id.blank?)) ? ro.employee_id : "Not Available"
      end
      meeting = MeetingScheduleManager.get_all_meeting_schedule_infos(center).first
      meeting_day = (meeting && meeting.schedule_begins_on) ? meeting.schedule_begins_on.strftime("%A") : "Not Specified"
      meeting_time = meeting ? meeting.meeting_begins_at : "Not Specified"
      loan_start_date = Lending.all(:administered_at_origin => center.id).aggregate(:scheduled_first_repayment_date)
      loan_cycle = Lending.all(:administered_at_origin => center.id).aggregate(:cycle_number)

      data[:centers][center] = {:branch_name => branch_name, :branch_id => branch_id, :center_id => center_id, :center_name => center_name,
        :center_creation_month => center_creation_month, :center_creation_year => center_creation_year, :ro_name => ro_name, :ro_code => ro_code,
        :meeting_day => meeting_day, :meeting_time => meeting_time, :loan_start_date => loan_start_date, :loan_cycle => loan_cycle}
    end
    data
  end
end
