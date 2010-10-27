class ExpenseHead
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String
  
  has n, :expense_vouchers

  validates_present :name
  validates_is_unique :name

end
