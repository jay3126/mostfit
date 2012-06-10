class LedgerAssignment
  include DataMapper::Resource
  include Constants::Properties, Constants::Transaction, Constants::Accounting

  property :id,                Serial
  property :counterparty_type, Enum.send('[]', *COUNTERPARTIES), :nullable => true
  property :counterparty_id,   *INTEGER_NOT_NULL
  property :product_type,      Enum.send('[]', *LEDGER_ASSIGNMENT_PRODUCT_TYPES), :nullable => true, :default => NOT_APPLICABLE
  property :product_id,        Integer
  property :created_at,        *CREATED_AT

  has 1, :ledger
  belongs_to :accounts_chart
  belongs_to :ledger_classification

  def self.record_ledger_assignment(product_accounts_chart, ledger_classification, product_type = nil, product_id = nil)
    if ledger_classification.is_product_specific
      raise ArgumentError, "Product type and ID are mandatory" unless (product_type and product_id)
    end
    assignment = {}
    assignment[:accounts_chart]    = product_accounts_chart
    assignment[:counterparty_type] = product_accounts_chart.counterparty_type
    assignment[:counterparty_id]   = product_accounts_chart.counterparty_id
    assignment[:ledger_classification] = ledger_classification
    assignment[:product_type]          = product_type if product_type
    assignment[:product_id]            = product_id if product_id
    ledger_assignment = first_or_create(assignment)
    raise Errors::DataError, ledger_assignment.errors.first.first if ledger_assignment.id.nil?
    ledger_assignment
  end

  def self.locate_ledger(counterparty_type, counterparty_id, ledger_classification, product_type = nil, product_id = nil)
    locate_ledger = {}
    locate_ledger[:counterparty_type] = counterparty_type
    locate_ledger[:counterparty_id]   = counterparty_id
    locate_ledger[:ledger_classification] = ledger_classification
    locate_ledger[:product_type]          = product_type if product_type
    locate_ledger[:product_id]            = product_id if product_id
    first(locate_ledger)
  end

end
