class PassbookLabelExtract < Report

  attr_accessor :biz_location_branch, :date

  def initialize(params, dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    @name = "Passbook Label Extract on #{@date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch] and (not (params[:biz_location_branch].empty?))) ? params[:biz_location_branch] : all_branch_ids
    get_parameters(params, user)
  end

  def name
    "Passbook Label Extract on #{@date}"
  end

  def self.name
    "Passbook Label Extract"
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
      staff_member = location_manage.manager_staff_member.name
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

    params = {:accounted_at_origin => @biz_location_branch}
    lending_ids = Lending.all(params).aggregate(:id)

    lending_ids.each do |l|

      loan = Lending.get(l)

      member = loan.loan_borrower.counterparty
      member_name = member ? member.name : "Not Specified"
      guarantor_name = (member and member.guarantor_name) ? member.guarantor_name : "Not Specified" 
      center = BizLocation.get(loan.administered_at_origin)
      center_id = center ? center.id : "Not Specified"
      center_name = center ? center.name : "Not Specified"
      meeting_address = (center and center.biz_location_address) ? center.biz_location_address : "Not Specified"
      meetings = meeting_facade.get_meeting_schedules(center).first
      meeting_day = (meetings and meetings.schedule_begins_on) ? meetings.schedule_begins_on.strftime("%A") : "Not Specified"
      meeting_time = meetings ? meetings.meeting_begins_at : "Not Specified"
      disbursal_date = loan.disbursal_date_value
      loan_id = loan.id
      loan_status = loan.status.to_s.humanize
      loan_start_date = loan.loan_base_schedule.first_receipt_on
      loan_account_number = loan.lan
      ewi_start_date = loan.loan_base_schedule.first_receipt_on
      ewi_end_date = loan.last_scheduled_date
      loan_amount = (loan and loan.applied_amount) ? MoneyManager.get_money_instance(Money.new(loan.applied_amount.to_i, :INR).to_s) : Money.default_money_amount(:INR)
      processing_or_upfornt_fee_due = reporting_facade.all_fees_due_per_loan(loan_id, @date)
      ewi_amount_due = loan.actual_total_due(@date)     
      branch = BizLocation.get(loan.accounted_at_origin)
      branch_name = branch ? branch.name : "Not Specified"
      branch_id = branch ? branch.id : "Not Specified"
      area = location_facade.get_parent(branch, @date)
      district = location_facade.get_parent(area, @date)
      district_name = district ? district.name : "Not Specified"
      district_id = district ? district.id : "Not Specified"
      group_name = (member and member.client_group) ? member.client_group.name : "Not Specified"
      ro_name = managed_by_staff(center.id, @date)
      purpose_of_loan = loan.loan_purpose
        
      data[loan] = {:member_name => member_name, :guarantor_name => guarantor_name, :center_name => center_name, :meeting_address => meeting_address, :center_id => center_id, :meeting_day => meeting_day, :meeting_time => meeting_time, :disbursal_date => disbursal_date, :loan_start_date => loan_start_date, :loan_account_number => loan_account_number, :ewi_start_date => ewi_start_date, :ewi_end_date => ewi_end_date, :loan_amount => loan_amount, :processing_or_upfornt_fee_due => processing_or_upfornt_fee_due, :ewi_amount_due => ewi_amount_due, :district_name => district_name, :district_id => district_id, :branch_name => branch_name, :branch_id => branch_id, :group_name => group_name, :ro_name => ro_name, :purpose_of_loan => purpose_of_loan, :loan_id => loan.id, :loan_status => loan_status}
    end
    data
  end
end
