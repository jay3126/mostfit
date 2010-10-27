class ExpenseVoucher
  include DataMapper::Resource

  EXPENSE_VOUCHER_TYPES = [:voucher]

  property :id,           Serial
  property :type,         Enum.send('[]',*EXPENSE_VOUCHER_TYPES), :index => true, :default => :voucher
  property :amount,       Float, :nullable => false, :index => true
  property :notation,     String, :length => 100, :nullable => true
  property :bill_number,  String, :nullable => true
  property :issued_to_name, String, :nullable => false
  property :issued_on,    DateTime, :nullable => false, :default => Time.now, :index => true
  property :created_at,   DateTime, :nullable => false, :default => Time.now, :index => true
  property :deleted_at,   ParanoidDateTime, :nullable => true, :index => true
  property :branch_id,    Integer, :nullable => true, :index => true

  belongs_to :branch, :model => 'Branch', :child_key => [:branch_id]
  belongs_to :expense_head

end
