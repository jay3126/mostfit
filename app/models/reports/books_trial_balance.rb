class BooksTrialBalance < Report

  attr_accessor :date, :cost_center

  def initialize(params, dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    @cost_center = (params and params[:cost_center] and (not params[:cost_center].empty?)) ? params[:cost_center] : nil
    get_parameters(params, user)
  end

  def get_cost_center(cost_center_id)
    return nil unless cost_center_id
    CostCenter.get(cost_center_id)
  end

  def self.name
    "Trial Balance with cost centers"
  end

  def name
    str = "Trial balance on #{date}"
    cost_center = get_cost_center(@cost_center)
    cost_center ? "#{str} for #{cost_center.name}" : str
  end

  def generate(param)
    data = {}
    cost_center = get_cost_center(@cost_center)
    posted_on_date = LedgerPosting.all(:effective_on => @date)
    ledgers = posted_on_date.collect {|post| post.ledger}
    ledgers.each { |account|
      account_balance = account.balance(@date, cost_center)
      next unless account_balance
      data[account] = account_balance
    }
    data
  end
end