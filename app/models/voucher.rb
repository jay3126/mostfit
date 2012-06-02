class Voucher
  include DataMapper::Resource
  include PostingValidator

  property :id,             Serial
  property :guid,           String, :length => 40, :nullable => false, :default => lambda {|obj, p| UUID.generate}
  property :total_amount,   Float, :nullable => false
  property :currency,       Enum.send('[]', *CURRENCIES), :nullable => false, :default => DEFAULT_CURRENCY
  property :effective_on,   Date, :nullable => false
  property :narration,      String, :length => 1024
  property :generated_mode, Enum.send('[]', *VOUCHER_MODES), :nullable => false
  property :created_at,     DateTime, :default => DateTime.now, :nullable => false

  has n, :ledger_postings

  validates_present :effective_on
  validates_with_method :validate_has_both_debits_and_credits?, :postings_are_each_valid?, :postings_are_valid_together?, :postings_add_up?, :validate_all_post_to_unique_accounts?

  def self.create_generated_voucher(total_amount, currency, effective_on, postings, notation = nil)
    create_voucher(total_amount, currency, effective_on, notation, postings, GENERATED_VOUCHER)
  end

  def self.get_postings(ledger, cost_center = nil, to_date = Date.today, from_date = nil)
    LedgerPosting.all_postings_on_ledger(ledger, to_date, from_date)
  end

  def self.find_by_date_and_cost_center(on_date)
    predicates = {}
    predicates[:effective_on] = on_date
    all(predicates)
  end

  def validate_has_both_debits_and_credits?
    has_both_debits_and_credits?(ledger_postings)
  end

  def postings_are_each_valid?
    ledger_postings.each { |posting|
      valid, message = LedgerBalance.valid_balance_obj?(posting)
      return [valid, message] unless valid
    }
    true
  end

  def postings_are_valid_together?
    LedgerBalance.can_add_balances?(*ledger_postings)
  end

  def postings_add_up?
    LedgerBalance.are_balanced?(*ledger_postings) ? true : [false, "postings do not balance"]
  end

  def validate_all_post_to_unique_accounts?
    all_post_to_unique_accounts?(ledger_postings)
  end

  def self.sort_chronologically(vouchers)
    vouchers.sort {|v1, v2| (v1.effective_on - v2.effective_on == 0) ? (v1.created_at - v2.created_at) : (v1.effective_on - v2.effective_on)}
  end

  private

  def self.create_voucher(total_amount, currency, effective_on, notation, postings, generated_mode)
    values = {}
    values[:total_amount] = total_amount
    values[:currency] = currency
    values[:effective_on] = effective_on
    values[:narration] = narration if narration
    values[:generated_mode] = generated_mode
    ledger_postings = []
    postings.each { |p|
      posting = {}
      posting[:effective_on] = effective_on
      posting[:amount] = p.amount
      posting[:currency] = p.currency
      posting[:effect] = p.effect
      posting[:ledger] = p.ledger
      ledger_postings.push(posting)
    }
    values[:ledger_postings] = ledger_postings
    create(values)
  end  

end
