# Immutable object for communication information about a posting
class PostingInfo

	attr_reader :amount, :currency, :posting_effect, :ledger

	def initialize(amount, currency, posting_effect, ledger)
	  @amount = amount; @currency = currency; @posting_effect = posting_effect; @ledger = ledger
	end

	def effect; @posting_effect; end
end

class PostingRule
  include DataMapper::Resource
  include Constants::Accounting
  
  property :id, Serial
  property :effect, Enum.send('[]', *ACCOUNTING_EFFECTS), :nullable => false
  property :percentage, Float, :nullable => false

  belongs_to :accounting_rule
  belongs_to :ledger

  validates_present :effect, :percentage, :accounting_rule, :ledger

  def to_s
    "#{effect} account '#{ledger.name}' #{percentage} percent of the amount"
  end

  def to_posting_info(total_amount, in_currency)
  	percentage_of_amount = (percentage * total_amount) / 100
  	PostingInfo.new(percentage_of_amount, in_currency, effect, ledger)
  end  

  def amount
  	percentage
  end

  def currency
  	PLACEHOLDER_FOR_CURRENCY
  end

end
