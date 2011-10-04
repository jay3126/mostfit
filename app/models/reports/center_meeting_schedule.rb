class CenterMeetingSchedule < Report
  attr_accessor :branch, :branch_id, :weekday

  validates_with_method :branch_id, :branch_should_be_selected  
  
  def initialize(params, dates, user)
    @branch = Branch.get(@branch_id) 
    @name = @branch ? "Center Meeting Schedule for #{@branch.name }" : "Center Meeting Schedule" 
    get_parameters(params, user)
  end

  def name
    "Center Meeting Schedule for #{@branch[0].name}"
  end

  def self.name
    "Center Meeting Schedule"
  end

  def generate
    weekday_hash = WEEKDAYS.map{|x| [WEEKDAYS.index(x), x]}.to_hash
    query = {}
    query = {:meeting_day => weekday_hash[@weekday]} if @weekday
    branch = Branch.get(@branch_id)
    data = branch.centers(query)
    return data
  end

end
