class DeviationReport < Report
  attr_accessor :from_date ,:to_date
  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 30
    @to_date = (dates and dates[:to_date]) ? dates[:to_date] : Date.today - 30



  end

  def name
    "Deviation Reports from #{from_date} to #{to_date}"
  end

  def self.name
    "static name"
  end

  def generate
    @responses=Response.all(:value_date.lte=>@to_date, :value_date.gte=>@from_date)
    debugger
    data =@responses

    data
  end


end