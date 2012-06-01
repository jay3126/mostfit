class LedgerPosting
  include DataMapper::Resource
  include Constants::Accounting, Constants::Money

  property :id,           Serial
  property :effective_on, Date, :nullable => false
  property :amount,       Float, :nullable => false
  property :currency,     Enum.send('[]', *CURRENCIES), :nullable => false, :default => DEFAULT_CURRENCY
  property :effect,       Enum.send('[]', *ACCOUNTING_EFFECTS), :nullable => false
  property :created_at,   DateTime, :nullable => false, :default => DateTime.now

  belongs_to :voucher
  belongs_to :ledger

  validates_present :effective_on, :amount, :currency, :effect, :voucher, :ledger

  validates_with_method :valid_accounting_effect?

  def to_balance
    LedgerBalance.to_balance_obj(amount, currency, effect)    
  end

  def valid_accounting_effect?
    LedgerBalance.valid_balance_obj?(self)
  end
  
  def self.all_postings_on_ledger(ledger, cost_center = nil, to_date = Date.today, from_date = nil)
    date_predicates = effective_on_date_predicates(to_date, from_date)
    voucher_predicates = {:cost_center => cost_center}
    voucher_predicates.merge!(date_predicates)
    query_voucher_value = Voucher.all(voucher_predicates)

    predicates = {}
    predicates[:ledger] = ledger
    predicates[:voucher] = query_voucher_value
    predicates.merge!(date_predicates)
    all(predicates)
  end

  def self.effective_on_date_predicates(to_date, from_date = nil)
    raise ArgumentError, "At least one date is required to be supplied" if (to_date.nil? and from_date.nil?)
    date_predicates = {}
    date_predicates[:effective_on.lte] = to_date if to_date
    date_predicates[:effective_on.gte] = from_date if from_date
    date_predicates
  end

end
