class TransactionSummary
  include DataMapper::Resource
  include Constants::Properties, Constants::Accounting
  
  property :id,              Serial
  property :amount,          Float, :nullable => false
  property :currency,        Enum.send('[]', *CURRENCIES), :nullable => false, :default => DEFAULT_CURRENCY
  property :effective_on,    Date, :nullable => false
  property :loan_id,         *INTEGER_NOT_NULL
  property :branch_id,       Integer, :nullable => false
  property :branch_name,     String, :nullable => false
  property :loan_product_id, Integer, :nullable => true
  property :fee_type_id,     Integer, :nullable => true
  property :created_at,      DateTime, :nullable => false, :default => DateTime.now
  property :updated_at,      DateTime, :nullable => false, :default => DateTime.now
  property :deleted_at,      ParanoidDateTime, :nullable => true
  property :was_processed,   Boolean, :nullable => false, :default => false

  belongs_to :money_category

  def to_info
    TransactionSummaryInfo.new(amount, currency, effective_on, loan_id, branch_id, branch_name, loan_product_id, fee_type_id, money_category)
  end

  def self.from_info(ts_info)
    with_values = populate_values(ts_info.amount, ts_info.currency, ts_info.effective_on, ts_info.loan_id,  ts_info.branch_id, ts_info.branch_name, ts_info.loan_product_id, ts_info.fee_type_id, ts_info.money_category)
    new(with_values)
  end

  def set_processed
  	update(:was_processed => true)
  end  

  def self.to_be_processed(options = {})
  	all(to_be_processed_predicate.merge(options))
  end

  MODEL_TO_QUERY = :model_to_query
  FIELD_MATCHES = :field_matches
  DATE_COMPARISON = :date_comparison
  AMOUNT_FIELD = :amount_field
  GROUP_BY_FIELD = :group_by_field

  INFO_MAPPING = {
    LOAN_DISBURSEMENT => { MODEL_TO_QUERY => Loan, AMOUNT_FIELD => :amount, DATE_COMPARISON => :disbursal_date, GROUP_BY_FIELD => :c_branch_id }, 
    PRINCIPAL_REPAID_RECEIVED_ON_LOANS_MADE => { MODEL_TO_QUERY => Payment, FIELD_MATCHES => { :type => :principal }, AMOUNT_FIELD => :amount, DATE_COMPARISON => :received_on, GROUP_BY_FIELD => :c_branch_id }, 
    INTEREST_RECEIVED_ON_LOANS_MADE => { MODEL_TO_QUERY => Payment, FIELD_MATCHES => { :type => :interest }, AMOUNT_FIELD => :amount, DATE_COMPARISON => :received_on, GROUP_BY_FIELD => :c_branch_id},
    FEE_RECEIVED_ON_LOANS_MADE => { MODEL_TO_QUERY => Payment, FIELD_MATCHES => { :type => :fees }, AMOUNT_FIELD => :amount, DATE_COMPARISON => :received_on, GROUP_BY_FIELD => :c_branch_id },
    OTHER_FEE_RECEIVED_SPECIFIC => { MODEL_TO_QUERY => Payment, FIELD_MATCHES => { :type => :fees }, AMOUNT_FIELD => :amount, DATE_COMPARISON => :received_on, GROUP_BY_FIELD => :c_branch_id},

    SCHEDULED_DISBURSEMENTS_OF_LOANS => { MODEL_TO_QUERY => Loan, AMOUNT_FIELD => :amount, DATE_COMPARISON => :scheduled_disbursal_date, GROUP_BY_FIELD => :c_branch_id },
    ACCRUE_REGULAR_PRINCIPAL_REPAYMENTS_ON_LOANS => { MODEL_TO_QUERY => LoanHistory, AMOUNT_FIELD => :scheduled_principal_due, DATE_COMPARISON => :date, GROUP_BY_FIELD => :branch_id },
    ACCRUE_REGULAR_INTEREST_RECEIPTS_ON_LOANS => { MODEL_TO_QUERY => LoanHistory, AMOUNT_FIELD => :scheduled_interest_due, DATE_COMPARISON => :date, GROUP_BY_FIELD => :branch_id }
  }

  def self.get_raw_transactions(money_category, on_date)
    money_category_key = get_money_category_key(money_category)
    values_hash = INFO_MAPPING[money_category_key]
    raise StandardError, "no mapping found for transactions for money_category: #{money_category_key}" unless values_hash
    model_to_query = values_hash[MODEL_TO_QUERY]
    date_comparison = values_hash[DATE_COMPARISON]
    field_matches = values_hash[FIELD_MATCHES]
    amount_field = values_hash[AMOUNT_FIELD]
    group_by_field = values_hash[GROUP_BY_FIELD]
    fee_type_id = money_category.specific_income_type_id == NOT_A_VALID_INCOME_TYPE_ID ? nil : money_category.specific_income_type_id

    get_transaction_rows(on_date, model_to_query, date_comparison, field_matches, fee_type_id)
  end

  def self.get_transactions_grouped(money_category, on_date)
    transaction_rows = get_raw_transactions(money_category, on_date)
    group_transactions_and_add_amounts(transaction_rows, group_by_field, amount_field)
  end

  def self.get_money_category_key(money_category)
    desc = money_category.description
    Regexp.new(OTHER_FEE_RECEIVED_SPECIFIC.to_s).match(desc) ? OTHER_FEE_RECEIVED_SPECIFIC : desc.to_sym
  end

  def self.get_transaction_rows(on_date, model_to_query, date_comparison, field_matches = {}, fee_type_id = nil)
    predicates = get_predicates(on_date, date_comparison, field_matches, fee_type_id)
    model_to_query.all(predicates)
  end

  def self.get_predicates(on_date, date_comparison, field_matches, fee_type_id)
    predicates = {}
    predicates[date_comparison] = on_date
    predicates.merge!(field_matches) if field_matches
    predicates.merge!(:fee_id => fee_type_id) if fee_type_id
    predicates
  end

  def self.group_transactions_and_add_amounts(transaction_rows, group_by_field, amount_field)
    grouped_and_added = {}
    grouped_transaction_rows = transaction_rows.group_by{|txn| txn.method(group_by_field).call}
    grouped_transaction_rows.each { |grouped_by, txns|
      amounts = txns.collect {|tx| tx.method(amount_field).call}
      total_amount = amounts.inject {|sum, amt| sum + amt}
      grouped_and_added[grouped_by] = total_amount
    }
    grouped_and_added
  end

  def self.generate_summary_info(money_category, on_date = Date.today)
    groups_and_amounts = get_transactions_grouped(money_category, on_date)
    summary_info = []
    branches_and_names = TransactionSummary.get_branches_and_names
    groups_and_amounts.each { |grouped_by_branch_id, amount|
      txn_summary_info = TransactionSummaryInfo.new(amount, DEFAULT_CURRENCY, on_date, grouped_by_branch_id, branches_and_names[grouped_by_branch_id], nil, money_category.specific_income_type_id, money_category)
      summary_info.push(txn_summary_info)
    }
    summary_info
  end

  def self.generate_raw_summary_info(money_category, on_date = Date.today)
    raw_transaction_rows = get_raw_transactions(money_category, on_date)
    raw_summary_info = []
    branches_and_names = TransactionSummary.get_branches_and_names
    amount_field = INFO_MAPPING[money_category.key][AMOUNT_FIELD]
    raw_transaction_rows.each { |ts|
      amount = ts.method(amount_field).call
      txn_summary_info = TransactionSummaryInfo.new(amount, DEFAULT_CURRENCY, on_date, ts.loan.id, ts.branch.id, branches_and_names[ts.branch.id], nil, money_category.specific_income_type_id, money_category)
      raw_summary_info.push(txn_summary_info)
    }
    raw_summary_info
  end

  def self.get_accrual_categories
    category_descriptions = [SCHEDULED_DISBURSEMENTS_OF_LOANS, ACCRUE_REGULAR_PRINCIPAL_REPAYMENTS_ON_LOANS, ACCRUE_REGULAR_INTEREST_RECEIPTS_ON_LOANS].collect {|desc| desc.to_s}
    MoneyCategory.all(:description => category_descriptions)
  end

  def self.get_receipt_categories
    receipt_categories = []
    category_descriptions = [LOAN_DISBURSEMENT, PRINCIPAL_REPAID_RECEIVED_ON_LOANS_MADE, INTEREST_RECEIVED_ON_LOANS_MADE].collect {|desc| desc.to_s}
    categories = MoneyCategory.all(:description => category_descriptions)
    categories.each {|cat| receipt_categories.push(cat)} if categories
    fee_categories = MoneyCategory.all(:specific_income_type_id.not => NOT_A_VALID_INCOME_TYPE_ID)
    fee_categories.each {|cat| receipt_categories.push(cat)} if fee_categories
    receipt_categories
  end

  def self.generate_accrual_summary_info(on_date = Date.today)
    summaries = []
    get_accrual_categories.each { |category|
      summaries.push(generate_raw_summary_info(category, on_date))
    }
    summaries.flatten
  end

  def self.generate_disbursements_and_receipts_summary_info(on_date = Date.today)
    summaries = []
    get_receipt_categories.each { |category|
      summaries.push(generate_summary_info(category, on_date))
    }
    summaries.flatten
  end

  def self.record_summary_from_info(summary_info)
    transaction_summary = from_info(summary_info)
    transaction_summary.save
  end

  #returns transaction summaries for a particular branch on a particular date 
  def self.find_on_date_for_branch(on_date, for_branch_id = nil)
    raise ArgumentError, "No date was supplied" unless (on_date and on_date.is_a?(Date))
    predicates = {:effective_on => on_date}
    predicates[:branch_id] = for_branch_id if (for_branch_id and for_branch_id > 0)
    all(predicates)
  end

  private

  def self.group_by_branch_and_add_amounts(transactions)
    transactions_by_branch = transactions.group_by {|txn| txn.c_branch_id}
    aggregate_txn_by_branch = {}
    transactions_by_branch.each { |branch_id, txns|
      txn_amounts = txns.collect{|tx| tx.amount}
      total = txn_amounts.inject {|sum, amount| sum + amount}
      aggregate_txn_by_branch[branch_id] = total
    }
    aggregate_txn_by_branch
  end

  def self.get_branches_and_names
    branches_and_names = {}
    Branch.all.each {|br| branches_and_names[br.id] = br.name} 
    branches_and_names
  end

  def self.to_be_processed_predicate
  	{ :was_processed => false }
  end

  def self.record_summary(transaction_type, amount, currency, effective_on, branch_id, branch_name, loan_product_id = nil, fee_type_id = nil)
   	values = populate_values(amount, currency, effective_on, branch_id, branch_name, loan_product_id, fee_type_id)
  	create_summary(transaction_type, values, loan_product_id, fee_type_id)
  end

  def self.create_summary(for_transaction_type, with_values, loan_product_id = nil, fee_type_id = nil)
    category = MoneyCategory.resolve_money_category(for_transaction_type, loan_product_id, fee_type_id)
    raise ArgumentError, "unable to resolve a money category for transaction type: #{for_transaction_type}, loan product: #{loan_product_id}, fee type: #{fee_type_id}" unless category
    with_values.merge!(:money_category => category)
    create(with_values)
  end

  def self.populate_values(amount, currency, effective_on, loan_id, branch_id, branch_name, loan_product_id = nil, fee_type_id = nil, money_category = nil)
  	values = {}
  	values[:amount] = amount
    values[:currency] = currency
  	values[:effective_on] = effective_on
    values[:loan_id] = loan_id
  	values[:branch_id] = branch_id
  	values[:branch_name] = branch_name
  	values[:loan_product_id] = loan_product_id || NOT_A_VALID_ASSET_TYPE_ID
  	values[:fee_type_id] = fee_type_id || NOT_A_VALID_INCOME_TYPE_ID
    values[:money_category] = money_category if money_category
    values
  end

end

class TransactionSummaryInfo
  include Constants::Accounting

  attr_reader :amount, :currency, :effective_on, :loan_id, :branch_id, :branch_name, :loan_product_id, :fee_type_id, :money_category

  def initialize(amount, currency, effective_on, loan_id, branch_id, branch_name, loan_product_id = nil, fee_type_id = nil, money_category = nil)
    @amount = amount; @currency = currency; @effective_on = effective_on; @loan_id = loan_id
    @branch_id = branch_id; @branch_name = branch_name
    @loan_product_id = loan_product_id || NOT_A_VALID_ASSET_TYPE_ID; @fee_type_id = fee_type_id || NOT_A_VALID_INCOME_TYPE_ID
    @money_category = money_category if money_category
  end

end
