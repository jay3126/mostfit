class ChequeBook
  include DataMapper::Resource

  property :id, Serial
  property :start_serial, Integer, :nullable => false
  property :end_serial, Integer, :nullable => false
  property :created_at, DateTime
  property :deleted_at, ParanoidDateTime
  property :created_by_user_id, Integer, :nullable => false
  property :deleted_by_user_id, Integer
  property :used, Boolean, :default => false
  property :valid, Boolean,:default => true
  property :issue_date, Date, :nullable => false, :default => Date.today

  belongs_to :bank_account
  has n, :cheque_leaves, :model => "ChequeLeaf"

  validates_with_method :start_serial, :start_serial_cannot_be_blank
  validates_with_method :end_serial, :end_serial_cannot_be_blank
  validates_with_method :start_serial, :start_serial_cannot_be_greater_than_end_serial
  validates_with_method :end_serial, :end_serial_cannot_be_less_than_end_serial

  def start_serial_cannot_be_blank
    return [false, "Start serial number cannot be blank"] if start_serial.nil?
    return true
  end

  def end_serial_cannot_be_blank
    return [false, "End serial number cannot be blank"] if end_serial.nil?
    return true
  end

  def start_serial_cannot_be_greater_than_end_serial
    return [false, "Starting serial number cannot be greater than end serial number"] if start_serial > end_serial
    return true
  end

  def end_serial_cannot_be_less_than_end_serial
    return [false, "End serial number cannot be less than start serial number"] if end_serial < start_serial
    return true
  end

  def serial_no
    "#{@start_serial} - #{@end_serial}"
  end
end
