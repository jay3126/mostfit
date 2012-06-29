class SimpleFeeProduct
  include DataMapper::Resource
  include Constants::Properties, Constants::Transaction

  property :id,                  Serial
  property :name,                *UNIQUE_NAME
  property :fee_charged_on_type, Enum.send('[]', *FEE_CHARGED_ON_TYPES), :nullable => false
  property :created_on,          *DATE_NOT_NULL
  property :created_at,          *CREATED_AT

  has n, :timed_amounts

  def effective_timed_amount(on_date = Date.today)
    self.timed_amounts.first(:effective_on.lte => on_date, :order => [:effective_on.desc])
  end

  def effective_fee_only_amount(on_date = Date.today)
    timed_amount = effective_timed_amount(on_date)
    timed_amount ? timed_amount.fee_money_amount : nil
  end

  def effective_tax_only_amount(on_date = Date.today)
    timed_amount = effective_timed_amount(on_date)
    timed_amount ? timed_amount.tax_money_amount : nil
  end

  def effective_total_amount(on_date = Date.today)
    timed_amount = effective_timed_amount(on_date)
    timed_amount ? timed_amount.total_money_amount : nil
  end

end
