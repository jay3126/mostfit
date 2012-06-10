class ProductPostingRule
  include DataMapper::Resource
  include Constants::Accounting

  property :id,             Serial
  property :product_amount, Enum.send('[]', *PRODUCT_AMOUNTS), :nullable => false
  property :effect,         Enum.send('[]', *ACCOUNTING_EFFECTS), :nullable => false

  belongs_to :ledger_classification
  belongs_to :product_accounting_rule

end

# A payment is made on a product
# The payment has an allocation that is several of principal receipt, interest receipt, advance receipt, advance adjusted, fee, or disbursement
# For each kind of payment, there is an effect on a corresponding ledger classification
# Each allocation goes to a ledger classification, and a ledger for that ledger classification must be located for the counterparty for the product
