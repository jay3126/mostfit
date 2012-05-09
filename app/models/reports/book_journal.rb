class BookJournal < Report

	attr_accessor :date

	def initialize(params, dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    get_parameters(params, user)
	end

	def self.name
    'Journal'
	end

  def name
    "Journal on #{date}"
  end

  def generate(params)
    data = {}
    vouchers_on_date = Voucher.all(:effective_on => @date)
    data[:effective_on] = @date
    data[:vouchers] = vouchers_on_date
    data
  end

end