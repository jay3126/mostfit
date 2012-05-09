class BooksBalanceSheet < Report

	attr_accessor :date

	def initialize(params, dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    get_parameters(params, user)
	end

  def self.name
    'Balance Sheet'
  end

  def name
    "Balance Sheet on #{date}"
  end

  def generate(params)
    data = {}
    data[Constants::Accounting::ASSETS] = {}
    data[Constants::Accounting::LIABILITIES] = {}

    [Constants::Accounting::ASSETS, Constants::Accounting::LIABILITIES].each { |acc_type|
      Ledger.all(:account_type => acc_type).each { |acc|
        data[acc_type][acc] = acc.balance(@date)
      }
    }
    data[:on_date] = @date

    data
  end

end