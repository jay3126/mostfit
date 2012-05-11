class PaymentTransaction
  include DataMapper::Resource
  include Constants::Money, Constants::Transaction
  
  property :id,                   Serial
  property :amount,               Integer, :nullable => false, :min => 0
  property :currency,             Enum.send('[]', *CURRENCIES), :nullable => false
  property :receipt_type,         Enum.send('[]', *RECEIVED_OR_PAID), :nullable => false
  property :on_product_type,      Enum.send('[]', *TRANSACTED_PRODUCTS), :nullable => false
  property :on_product_id,        Integer, :nullable => false
  property :by_counterparty_type, Enum.send('[]', *COUNTERPARTIES), :nullable => false
  property :by_counterparty_id,   Integer, :nullable => false
  property :performed_at,          Integer, :nullable => false
  property :accounted_at,         Integer, :nullable => false
  property :performed_by,         Integer, :nullable => false
  property :recorded_by,          Integer, :nullable => false
  property :effective_on,         Date, :nullable => false
  property :created_at,           DateTime, :nullable => false, :default => DateTime.now

end