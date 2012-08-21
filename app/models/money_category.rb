class MoneyCategory
  include DataMapper::Resource
  include Constants::Accounting
  
  property :id,                      Serial
  property :description,             String, :length => 1024, :nullable => false
  property :transacted_category,     Enum.send('[]', *TRANSACTED_CATEGORIES), :nullable => false
  property :receivable_category,     Enum.send('[]', *RECEIVABLE_CATEGORIES), :nullable => false
  property :asset_category,          Enum.send('[]', *ASSET_CATEGORIES), :nullable => false,  :default => NOT_AN_ASSET
  property :liability_category,      Enum.send('[]', *LIABILITY_CATEGORIES), :nullable => false, :default => NOT_A_LIABILITY
  property :income_category,         Enum.send('[]', *INCOME_CATEGORIES), :nullable => false, :default => NOT_AN_INCOME
  property :expense_category,        Enum.send('[]', *EXPENSE_CATEGORIES), :nullable => false, :default => NOT_AN_EXPENSE
  property :owned_category,          Enum.send('[]', *OWNED_CATEGORIES), :nullable => false
  property :specific_asset_type_id,  Integer, :nullable => false, :default => NOT_A_VALID_ASSET_TYPE_ID
  property :specific_income_type_id, Integer, :nullable => false, :default => NOT_A_VALID_INCOME_TYPE_ID
  property :is_reversed,             Boolean, :nullable => false

  has 1, :accounting_rule
#  has n, :transaction_summaries

  validates_with_method :account_type_category_was_set?

  DEFAULT_TRANSACTION_CATEGORIES = [LOAN_DISBURSEMENT, PRINCIPAL_REPAID_RECEIVED_ON_LOANS_MADE, INTEREST_RECEIVED_ON_LOANS_MADE]
  DEFAULT_ACCRUAL_CATEGORIES = [SCHEDULED_DISBURSEMENTS_OF_LOANS, ACCRUE_REGULAR_PRINCIPAL_REPAYMENTS_ON_LOANS, ACCRUE_REGULAR_INTEREST_RECEIPTS_ON_LOANS, ACCRUE_BROKEN_PERIOD_INTEREST_RECEIPTS_ON_LOANS, ACCRUE_NEW_PERIOD_REVERSALS_OF_BROKEN_PERIOD_INTEREST_RECEIPTS]

  TRANSACTION_CATEGORIES_VALUES = {
    LOAN_DISBURSEMENT => { :transacted_category => TRANSACTION, :receivable_category => TO_PAY, :asset_category => LOANS_MADE, :owned_category => OWNED, :is_reversed => NOT_REVERSED },
    PRINCIPAL_REPAID_RECEIVED_ON_LOANS_MADE => { :transacted_category => TRANSACTION, :receivable_category => TO_RECEIVE, :asset_category => LOANS_MADE, :owned_category => OWNED, :is_reversed => NOT_REVERSED },
    INTEREST_RECEIVED_ON_LOANS_MADE => { :transacted_category => TRANSACTION, :receivable_category => TO_RECEIVE, :income_category => INTEREST_INCOME_FROM_LOANS, :owned_category => OWNED, :is_reversed => NOT_REVERSED },
    FEE_RECEIVED_ON_LOANS_MADE => { :transacted_category => TRANSACTION, :receivable_category => TO_RECEIVE, :income_category => FEE_INCOME_FROM_LOANS, :owned_category => OWNED, :is_reversed => NOT_REVERSED },
    OTHER_FEE_RECEIVED_SPECIFIC => { :transacted_category => TRANSACTION, :receivable_category => TO_RECEIVE, :income_category => OTHER_FEE_INCOME, :owned_category => OWNED, :is_reversed => NOT_REVERSED }, 
  }

  ACCRUAL_CATEGORIES_VALUES = {
    SCHEDULED_DISBURSEMENTS_OF_LOANS => { :transacted_category => ACCRUAL, :receivable_category => TO_PAY, :asset_category => LOANS_MADE, :owned_category => OWNED, :is_reversed => NOT_REVERSED },
    ACCRUE_REGULAR_PRINCIPAL_REPAYMENTS_ON_LOANS => { :transacted_category => ACCRUAL, :receivable_category => TO_RECEIVE, :asset_category => LOANS_MADE, :owned_category => OWNED, :is_reversed => NOT_REVERSED },
    ACCRUE_REGULAR_INTEREST_RECEIPTS_ON_LOANS => { :transacted_category => ACCRUAL, :receivable_category => TO_RECEIVE, :income_category => INTEREST_INCOME_FROM_LOANS, :owned_category => OWNED, :is_reversed => NOT_REVERSED },
    ACCRUE_BROKEN_PERIOD_INTEREST_RECEIPTS_ON_LOANS => { :transacted_category => ACCRUAL, :receivable_category => TO_RECEIVE, :income_category => INTEREST_INCOME_FROM_LOANS, :owned_category => OWNED, :is_reversed => NOT_REVERSED },
    ACCRUE_NEW_PERIOD_REVERSALS_OF_BROKEN_PERIOD_INTEREST_RECEIPTS => { :transacted_category => ACCRUAL, :receivable_category => TO_RECEIVE, :income_category => INTEREST_INCOME_FROM_LOANS, :owned_category => OWNED, :is_reversed => NOT_REVERSED }
  }

  def key; self.description.to_sym; end

  def account_type_category_was_set?
    account_type_category ? true : [false, "no account type category was set"]
  end

  def account_type_category
    return asset_category unless asset_category == NOT_AN_ASSET
    return liability_category unless liability_category == NOT_A_LIABILITY
    return income_category unless income_category == NOT_AN_INCOME
    return expense_category unless expense_category == NOT_AN_EXPENSE
    nil
  end

  def self.create_default_money_categories
    (DEFAULT_TRANSACTION_CATEGORIES + DEFAULT_ACCRUAL_CATEGORIES).flatten.each { |category|
      values_for_category = TRANSACTION_CATEGORIES_VALUES[category] || ACCRUAL_CATEGORIES_VALUES[category]
      raise StandardError, "missing default money category values for #{category}" unless values_for_category
      values_for_category.merge!(:description => category.to_s)
      MoneyCategory.first_or_create(values_for_category)
    }
    create_money_categories_for_fee_receipts
  end

  def self.create_money_categories_for_fee_receipts
    Fee.all.each { |fee| create_category_for_other_fee_received(fee.id) }
  end

  def self.resolve_money_category(by_transaction_type, asset_type_id = nil, income_type_id = nil)
    values_for_type = TRANSACTION_CATEGORIES_VALUES[by_transaction_type] || ACCRUAL_CATEGORIES_VALUES[by_transaction_type]
    raise ArgumentError, "unable to resolve money category values for transaction type #{by_transaction_type}" unless values_for_type    
    
    for_asset_type_id = asset_type_id || NOT_A_VALID_ASSET_TYPE_ID
    values_for_type.merge!(:specific_asset_type_id => for_asset_type_id)
    for_income_type_id = income_type_id || NOT_A_VALID_INCOME_TYPE_ID
    values_for_type.merge!(:specific_income_type_id => for_income_type_id)
    
    first(values_for_type)
  end

  def self.resolve_money_category_for_payment(payment_type, fee_id = nil)
    transaction_type = nil
    case payment_type
    when :principal then transaction_type = PRINCIPAL_REPAID_RECEIVED_ON_LOANS_MADE
    when :interest then transaction_type = INTEREST_RECEIVED_ON_LOANS_MADE
    when :fees then transaction_type = OTHER_FEE_RECEIVED_SPECIFIC
    end
    category = resolve_money_category(transaction_type, nil, fee_id)
  end

  def self.create_category_for_other_fee_received(fee_id)
    raise ArgumentError, "unable to create a money category for specific fee, since no fee ID was specified: #{fee_id}" unless (fee_id > 0 and (fee_id != NOT_A_VALID_INCOME_TYPE_ID))
    values_for_type = TRANSACTION_CATEGORIES_VALUES[OTHER_FEE_RECEIVED_SPECIFIC]
    values_for_type.merge!(:description => "#{OTHER_FEE_RECEIVED_SPECIFIC} for #{fee_id}")
    values_for_type.merge!(:specific_income_type_id => fee_id)
    mc = MoneyCategory.first_or_create(values_for_type)
  end

  def to_s
    @description.sentencecase
  end
end
