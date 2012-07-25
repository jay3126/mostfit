class DayBook < Report
  attr_accessor :date, :ledger_list

  def initialize(params, dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    @ledger = params[:ledger_list] rescue ""
    @name = "Day book as on #{@date}"
    get_parameters(params, user)
  end

  def generate
    @data = []
    date_params = {:effective_on => @date}
    voucher_on_date = Voucher.all(date_params)
    voucher_on_date.each do |voucher|
      ledger_posting = voucher.ledger_postings
      @data << (ledger_posting.collect{|lp|
          lp.voucher if lp.ledger == Ledger.get(@ledger)
        })
    end
    @data.flatten.compact.uniq
  end

  def name
    "Day book for #{date}"
  end

  def self.name
    "Day book"
  end

end
