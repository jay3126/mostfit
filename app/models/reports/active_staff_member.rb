#This report is a specially made for Moral. Feature request #1834.

class ActiveStaffMember < Report

  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 30
    @to_date = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Staff Member report from #{@from_date} to #{@to_date}"
  end

  def name
    "Staff Member report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Active Staff Member Report"
  end

  def generate
    query = {}
    query = {:active => true, :creation_date.gte => @from_date, :creation_date.lte => @to_date}
    staff_members = StaffMember.all(query)
    data = staff_members
  end
end
