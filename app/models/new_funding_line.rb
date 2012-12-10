class NewFundingLine
  include DataMapper::Resource
  include Constants::Properties

  property :id,             Serial
  property :amount,         *MONEY_AMOUNT
  property :currency,       *CURRENCY
  property :sanction_date,  *DATE
  property :created_by,     Integer
  property :created_at,     *CREATED_AT
  property :reference,      Integer, :unique => true    #property added for upload functionality.

  belongs_to :new_funder
  has n, :new_tranches
  belongs_to :upload, :nullable => true
  
  def money_amounts; [:amount]; end
  def funding_line_money_amount; to_money_amount(:amount); end

  def name
    "#{new_funder.name}: #{funding_line_money_amount}"
  end

  #this method is for upload functionality.
  def self.from_csv(row, headers)
    funder = NewFunder.create(:name => row[headers[:funder_name]], :created_by => User.first.id)
    money_amount = MoneyManager.get_money_instance(row[headers[:amount]])
    obj = new(:amount => money_amount.amount, :currency => money_amount.currency, :sanction_date => Date.parse(row[headers[:sanction_date]]),
              :new_funder_id => funder.id, :created_by => User.first.id, :reference => row[headers[:reference]],
              :upload_id => row[headers[:upload_id]])
    [obj.save!, obj]
  end

end
