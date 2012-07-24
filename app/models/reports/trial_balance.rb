class TrialBalance < Report
  
  attr_accessor :date

  def initialize(params,dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    get_parameters(params, user)
  end

  def name
    "Trial Balance for date #{@date}"
  end

  def self.name
    "Trial Balance"
  end
  
  def generate(param)
    data = []
    all_ledgers = Ledger.all
    all_ledgers.each do |ledger|
      ledger_balance = ledger.balance(@date)
      if ledger_balance
        data << ledger
      end
    end
    data
  end

end
