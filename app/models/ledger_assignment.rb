class LedgerAssignment
  include DataMapper::Resource
  include Constants::Properties, Constants::Transaction

  property :id,                Serial
  property :counterparty_type, Enum.send('[]', *COUNTERPARTIES), :nullable => true
  property :counterparty_id,   *INTEGER_NOT_NULL
  property :product_type,      Enum.send('[]', *TRANSACTED_PRODUCTS), :nullable => true
  property :product_id,        Integer
  property :created_at,        *CREATED_AT

  has 1, :ledger
  belongs_to :accounts_chart
  belongs_to :ledger_classification

end
