class GuarantorReport < Report
  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def self.name
    "Guarantor Register"
  end

  def generate
    params = {:created_at.gte => from_date, :created_at.lte => to_date, :order => [:id]}
    Guarantor.all(params) 
  end
end
