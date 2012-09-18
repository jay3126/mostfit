class BankAccount
  include DataMapper::Resource
  
  property :id,         Serial
  property :name,       String, :length => 100, :nullable => false, :index => true
  property :account_no, String, :nullable => false, :index => true
  property :created_at, DateTime
  property :created_by_user_id, Integer, :nullable => false


  has n, :money_deposits
  has n, :cheque_books, :model => 'ChequeBook'

  belongs_to :bank_branch
  belongs_to :user, :child_key => [:created_by_user_id], :model => 'User'

  validates_present :name, :scope => :bank_branch_id
  validates_present :account_no
  validates_with_method :account_no, :method => :unique_branch_account_no?

  def unique_branch_account_no?
    bank = self.bank_branch.bank
    branches = bank.bank_branches
    accounts = BankAccount.all(:bank_branch_id => branches.map(&:id))
    if accounts.map(&:account_no).include?(self.account_no)
      return [false, "Account No. is already used"]
    else
      return true
    end
  end
end
