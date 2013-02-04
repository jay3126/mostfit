#this report is to keep a track of various logins in the system.
class UserAccessReport < Report
  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "User Access Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def name
    "User Access Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "User Access Report"
  end

  def generate

    data = {}

    params = {:login_date.gte => @from_date, :login_date.lte => @to_date}
    logins = LoginInstance.all(params)

    logins.each do |log|
      login_date = log.login_date_of_user
      login_time = log.login_time_of_user_formatted
      logout_date = log.logout_date_of_user
      logout_time = log.logout_time_of_user_formatted
    
      #finding out the user.
      user = log.user
      logged_in_user_id = (user and not (user.nil?)) ? user.id : "User not specified"
      logged_in_user_name = (user and user.name and not (user.nil?)) ? user.name : "User not specified"

      #finding out the staff_member who is logged in.
      staff_member = log.user.staff_member
      staff_member_name = (staff_member and staff_member.name and (not staff_member.nil?)) ? staff_member.name : "Staff Member not attached"
      staff_member_id = (staff_member and (not staff_member.nil?)) ? staff_member.id : "Staff Member not attached"
      
      #finding out the staff's designation.
      designation = log.user.staff_member.designation
      designation_id = (designation and (not designation.nil?)) ? designation.id : "Designation not specified"
      designation_name = (designation and designation.name and (not designation.nil?)) ? designation.name : "Designation not specified"
      designation_role = (designation and designation.role_class and (not designation.nil?)) ? designation.role_class.humanize : "Role not specified"

      data[log.id] = {:login_time => login_time, :logout_time => logout_time, :logged_in_user_id => logged_in_user_id, :logged_in_user_name => logged_in_user_name,
        :staff_member_name => staff_member_name, :staff_member_id => staff_member_id, :designation_id => designation_id, :designation_name => designation_name,
        :designation_role => designation_role, :login_date => login_date, :logout_date => logout_date
      }
    end
    data
  end
end