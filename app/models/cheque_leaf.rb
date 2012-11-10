class ChequeLeaf
  include DataMapper::Resource
  include Constants::Properties
  include Constants::Transaction

  property :id, Serial
  property :cheque_issue_date, Date, :nullable => false, :default => Date.today
  property :amount,   *MONEY_AMOUNT_NULL
  property :type, Enum.send('[]', *CHEQUE_LEAF_TYPE), :nullable => false, :default => NOT_DEFINED
  property :valid, Boolean, :default => true
  property :used, Boolean, :default => false
  property :created_at, DateTime
  property :deleted_at, ParanoidDateTime
  property :serial_number, Integer, :nullable => false
  property :issued_by_staff, Integer, :nullable => false
  property :bank_account_id, Integer, :nullable => false
  property :bank_branch_id, Integer, :nullable => false
  property :biz_location_id, Integer, :nullable => false

  belongs_to :cheque_book

  def self.mark_cheque_leaf_as_used(cheque_number)
    cl = ChequeLeaf.first(:serial_number => cheque_number)
    cl.used = true
    cl.save!
  end

end
