class NewTranch
  include DataMapper::Resource
  include Constants::Properties
  include Constants::TranchAssignment

  property :id,                  Serial
  property :amount,              *MONEY_AMOUNT
  property :currency,            *CURRENCY
  property :interest_rate,       *FLOAT_NOT_NULL
  property :disbursal_date,      *Date
  property :first_payment_date,  *Date
  property :last_payment_date,   Date
  property :assignment_type,     Enum.send('[]', *TRANCH_ASSIGNMENT_TYPES), :default => Constants::TranchAssignment::NOT_ASSIGNED
  property :created_by,          Integer
  property :created_at,          *CREATED_AT
  property :reference,           Integer, :unique => true  #property added for upload functionality.

  belongs_to :new_funding_line
  belongs_to :upload, :nullable => true

  validates_with_method  :disbursal_date,       :method => :disbursal_not_before_sanction?
  validates_with_method  :first_payment_date,   :method => :first_payment_not_equalto_disbursal?
  validates_with_method  :first_payment_date,   :method => :first_payment_not_before_disbursal?
  validates_with_method  :last_payment_date,    :method => :last_payment_not_before_first_payment_or_disbursal?
  validates_with_method  :assignment_type,      :method => :tranch_assignment_not_blank?
  validates_present      :amount, :interest_rate, :disbursal_date, :first_payment_date, :assignment_type

  def money_amounts; [:amount]; end

  def tranch_money_amount; to_money_amount(:amount); end

  def name
    "#{tranch_money_amount}@#{interest_rate}"
  end

  #this function is for upload functionality.
  def self.from_csv(row, headers)
    funder = NewFunder.first(:name => row[headers[:funder_name]])
    funding_line = NewFundingLine.first(:amount => MoneyManager.get_money_instance(row[headers[:funding_line]]).amount, :new_funder_id => funder.id)

    if row[headers[:assignment_type]] == "e"
      assignment_type = "encumbrance"
    elsif row[headers[:assignment_type]] == "s"
      assignment_type = "securitization"
    elsif row[headers[:assignment_type]] == "ae"
      assignment_type = "encumbrance"
    end

    money_amount = MoneyManager.get_money_instance(row[headers[:amount]])
    obj = new(:new_funding_line_id => funding_line.id, :amount => money_amount.amount,
              :currency => money_amount.currency, :interest_rate => row[headers[:interest_rate]], 
              :reference => row[headers[:reference]], :disbursal_date => Date.parse(row[headers[:disbursal_date]]),
              :first_payment_date => Date.parse(row[headers[:first_payment_date]]),
              :last_payment_date => Date.parse(row[headers[:last_payment_date]]), :assignment_type => assignment_type,
              :created_by => User.first.id, :upload_id => row[headers[:upload_id]])
    [obj.save!, obj]
  end

  private

  def first_payment_not_before_disbursal?
    return ((!first_payment_date.blank? && first_payment_date < disbursal_date)) ? [false, "First payment date must not before disbursal date "] : true
  end

  def first_payment_not_equalto_disbursal?
    return ((!first_payment_date.blank? && first_payment_date == disbursal_date)) ? [false, "First payment date must not equal to disbursal date "] : true
  end

  def last_payment_not_before_first_payment_or_disbursal?
    return (!last_payment_date.blank? && ((last_payment_date < disbursal_date) || (last_payment_date < first_payment_date))) ? [false, "Last payment date must not before disbursal date or First Payment date "] : true
  end

  def disbursal_not_before_sanction?
    return (!disbursal_date.blank? && disbursal_date < self.new_funding_line.sanction_date) ? [false, "Disbursal date must not before Funding line sanction date "] : true
  end

  def tranch_assignment_not_blank?
    return (assignment_type == Constants::TranchAssignment::NOT_ASSIGNED) ? [false, "Tranch must be either Securitized or Encumbered"] : true
  end
  
end