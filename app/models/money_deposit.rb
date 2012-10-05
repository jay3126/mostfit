class MoneyDeposit
  include DataMapper::Resource
  include Constants::Properties
  include Constants::MoneyDepositVerificationStatus
  
  property :id,                     Serial
  property :amount,                 *MONEY_AMOUNT
  property :currency,               *CURRENCY
  property :created_on,             *DATE_NOT_NULL
  property :created_at,             *CREATED_AT
  property :created_by_user_id,     *INTEGER_NOT_NULL
  property :created_by_staff_id,    *INTEGER_NOT_NULL
  property :verification_status,    Enum.send('[]', *MONEY_DEPOSIT_VERIFICATION_STATUSES), :nullable => false, :default => PENDING_VERIFICATION
  property :verified_by_staff_id,   Integer, :nullable => true
  property :verified_on,            *DATE
  property :verified_by_user_id,    Integer, :nullable => true
  property :at_location_id,         *INTEGER_NOT_NULL

  belongs_to :bank_account
  belongs_to :user, :child_key => [:created_by_user_id], :model => 'User'
  belongs_to :staff_member, :child_key => [:created_by_staff_id], :model => 'StaffMember'

  def varified_by_staff; StaffMember.get(self.verified_by_staff_id); end;
  def location; BizLocation.get(self.at_location_id); end;
  validates_present :created_by_staff_id

  def money_amounts; [:amount]; end

  def deposit_money_amount; to_money_amount(:amount); end

  def self.record_money_deposit(deposit_money_amount, deposited_bank_account_id, deposited_on, deposited_by, recorded_by, at_location_id)
    money_deposit = {}
    money_deposit[:amount] = deposit_money_amount.amount
    money_deposit[:currency] = deposit_money_amount.currency
    money_deposit[:created_on] = deposited_on
    money_deposit[:created_by_staff_id] = deposited_by
    money_deposit[:created_by_user_id]  = recorded_by
    money_deposit[:bank_account_id] = deposited_bank_account_id
    money_deposit[:at_location_id] = at_location_id
    deposit = create(money_deposit)
    raise Errors::DataError, deposit.errors.first.first unless deposit.saved?
    deposit
  end

  def varified?
    self.verification_status == VERIFIED_CONFIRMED
  end

  def self.location_amount_on_status(status, on_date = Date.today)
    deposits = all(:verification_status => status, :created_on => on_date)
    deposits.blank? ? MoneyManager.default_zero_money : deposits.map(&:deposit_money_amount).sum
  end

  validates_with_method  :created_on, :method => :deposit_not_in_future?

  def deposit_not_in_future?
    return true if created_on and (created_on<=Date.today)
    [false, "Deposit cannot be done on future dates"]
  end

end
