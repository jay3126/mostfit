class CreditBureauReport < Report
  attr_accessor :from_date, :to_date
  
  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : (Date.today - 30)
    @to_date = (dates and dates[:to_date]) ? dates[:to_date] : Date.today 
    get_parameters(params, user)
  end

  def name
    "Credit Bureau Report from #{@from_date} to #{to_date}"
  end
  
  def self.name
    "Credit Bureau Report"
  end

  def generate
    @data = {}
    from_date_time = DateTime.new(@from_date.year, @from_date.month, @from_date.day)
    to_date_time = DateTime.new(@to_date.year, @to_date.month, @to_date.day, 23, 59, 59)
    requests = OverlapReportRequest.all(:created_at.gte => from_date_time, :created_at.lte => to_date_time).aggregate(:created_at, :id.count).each.map{|x| {Date.new(x[0].year, x[0].month, x[0].day) => x[1]}}.sum
    responses = OverlapReportResponse.all(:created_at.gte => from_date_time, :created_at.lte => to_date_time).aggregate(:created_at, :id.count).each.map{|x| {Date.new(x[0].year, x[0].month, x[0].day) => x[1]}}.sum
    responses_status = OverlapReportResponse.all(:created_at.gte => from_date_time, :created_at.lte => to_date_time).group_by{|x| x.status}
    positive_responses = responses_status["positive"].map{|x| {Date.new(x.created_at.year, x.created_at.month, x.created_at.day) => 1}}.sum if responses_status["positive"].is_a?(Array)
    negative_responses = responses_status["negative"].map{|x| {Date.new(x.created_at.year, x.created_at.month, x.created_at.day) => 1}}.sum if responses_status["negative"].is_a?(Array)
    dates = [requests.keys, responses.keys].flatten.uniq
    dates.each do |date|
      @data[date] = {
        :request           => (requests.nil? ? nil : requests[date]), 
        :response          => (responses.nil? ? nil : responses[date]),
        :positive_response => (positive_responses.nil? ? nil : positive_responses[date]),
        :negative_response => (negative_responses.nil? ? nil : negative_responses[date])
      }
    end
    @data
  end

end
