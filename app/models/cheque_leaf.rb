class ChequeLeaf
  include DataMapper::Resource

  property :id, Serial
  property :start_serial, Integer, :nullable => false
  property :end_serial, Integer, :nullable => false
  property :deleted, Boolean, :default => false
  property :created_at, DateTime
  property :deleted_at, DateTime
  property :created_by_user_id, Integer, :nullable => false
  property :deleted_by_user_id, Integer
  property :used, Boolean, :default => false
  property :valid, Boolean,:default => true
  property :issue_date, Date, :nullable => false, :default => Date.today


  belongs_to :bank_account

  def serial_no
    "#{@start_serial} - #{@end_serial}"
  end
end
