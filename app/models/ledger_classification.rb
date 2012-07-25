class LedgerClassification
  include DataMapper::Resource
  include Constants::Accounting
  include Comparable

  property :id,               Serial
  property :account_type,     Enum.send('[]', *ACCOUNT_TYPES), :nullable => false
  property :account_purpose,  Enum.send('[]', *PRODUCT_LEDGER_TYPES), :nullable => false
  property :is_product_specific, Boolean, :nullable => false

  has n, :ledgers
  has n, :ledger_assignments
  has n, :product_posting_rules

  # The account type followed by the account purpose
  def to_s
    "#{self.account_type}: #{self.account_purpose}"
  end

  # Setup the default ledger classifications
  def self.create_default_ledger_classifications
    PRODUCT_LEDGER_TYPES.each { |ledger_type|
      first_or_create(
          :account_type => CUSTOMER_LEDGER_CLASSIFICATION[ledger_type],
          :account_purpose => ledger_type,
          :is_product_specific => CUSTOMER_LOAN_PRODUCT_SPECIFIC_LEDGER_TYPES.include?(ledger_type)
      )
    }
  end

  # Given a string, returns the corresponding ledger classification 
  def self.resolve(ledger_classification_string)
    first(:account_purpose => ledger_classification_string.to_sym)
  end

  def <=>(other)
    other.is_a?(LedgerClassification) ? (self.id <=> other.id) : nil
  end

end
