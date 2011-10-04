class CenterMeetingSchedule < Report
  attr_accessor :branch, :branch_id
  
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
    branch = Branch.get(@branch_id)
    data = branch.centers
    return data
  end

end
