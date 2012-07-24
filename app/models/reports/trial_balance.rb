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
    data = {}
    default_currency = MoneyManager.get_default_currency
    zero_credit_balance = LedgerBalance.zero_credit_balance(default_currency)
    zero_debit_balance = LedgerBalance.zero_debit_balance(default_currency)

    ledgers = Ledger.all
    ledgers.group_by{|x| [x.account_type]}.each{|c, l| l.each{|x| data.merge!(c => {x => x.balance(Date.today)})}}
    data
  end

end