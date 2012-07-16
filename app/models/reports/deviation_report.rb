class DeviationReport < Report
  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 30
    @to_date = (dates and dates[:to_date]) ? dates[:to_date] : Date.today - 30


  end

  def name
    "Deviation Reports from #{from_date} to #{to_date}"
  end

  def self.name
    "Deviation Report"
  end

  def generate
    if @to_date<@from_date
      data="Validation"
      return data
    else
      @responses=Response.all(:value_date.lte => @to_date, :value_date.gte => @from_date)


      data =@responses

      data
    end
  end


end