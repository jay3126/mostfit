class AccountingRule
  include DataMapper::Resource
  include PostingValidator
  
  property :id,         Serial
  property :name,       String, :nullable => false, :unique => true
  property :created_at, DateTime, :nullable => false, :default => DateTime.now

  has n, :posting_rules
  belongs_to :money_category

  validates_present :money_category
  validates_with_method :validate_has_both_debit_and_credit_rules?, :validate_each_side_accounts_fully?, :validate_all_post_to_unique_accounts?

  def validate_has_both_debit_and_credit_rules?
    has_both_debits_and_credits?(posting_rules)
  end

  def validate_each_side_accounts_fully?
    each_side_accounts_fully?(posting_rules)
  end

  def validate_all_post_to_unique_accounts?
    all_post_to_unique_accounts?(posting_rules)
  end

  def get_posting_info(total_amount, currency)
    posting_rules.collect { |rule| rule.to_posting_info(total_amount, currency) }
  end

  def self.load_accounting_rules(rules_hash)
    other_fee_received_specific_regex = Regexp.new(OTHER_FEE_RECEIVED_SPECIFIC.to_s)
    rules_hash.keys.each { |key|
      category = other_fee_received_specific_regex.match(key) ? MoneyCategory.first(:specific_income_type_id => rules_hash[key]['specific_income_type_id']) : MoneyCategory.first(:description => key)
      next if first(:money_category => category)

      rule_values = rules_hash[key] 

      debits = rule_values['debits']
      debit_ledger = Ledger.first(:name => debits['ledger'])
      debit_rule = PostingRule.new(
        :effect => Constants::Accounting::DEBIT_EFFECT,
        :percentage => debits['percentage'],
        :ledger => debit_ledger
      )

      credits = rule_values['credits']
      credit_ledger = Ledger.first(:name => credits['ledger'])
      credit_rule = PostingRule.new(
        :effect => Constants::Accounting::CREDIT_EFFECT,
        :percentage => credits['percentage'],
        :ledger => credit_ledger
      )
      
      rule = new(:money_category => category, :name => category.description)
      rule.posting_rules << debit_rule
      rule.posting_rules << credit_rule
      rule.save
    }
  end

end
