class LedgerClassification
  include DataMapper::Resource
  include Constants::Accounting

  property :id, Serial
  property :account_type,    Enum.send('[]', *ACCOUNT_TYPES), :nullable => false
  property :account_purpose, Enum.send('[]', *PRODUCT_LEDGER_TYPES), :nullable => false

  has n, :ledgers
  has n, :ledger_assignments
  has n, :product_posting_rules

  def self.create_default_ledger_classifications
    PRODUCT_LEDGER_TYPES.each { |ledger_type|
      first_or_create(
          :account_type => CUSTOMER_LEDGER_CLASSIFICATION[ledger_type],
          :account_purpose => ledger_type
      )
    }
  end

  def self.resolve(ledger_classification_string)
    first(:account_purpose => ledger_classification_string.to_sym)
  end

end
