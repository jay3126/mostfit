class ProductAccountingRule
  include DataMapper::Resource
  include Constants::Properties, Constants::Accounting

  property :id, Serial
  property :product_action, Enum.send('[]', *PRODUCT_ACTIONS), :nullable => false
  property :created_at, *CREATED_AT

  has n, :product_posting_rules

  def get_posting_info(payment_transaction, payment_allocation)
    self.product_posting_rules.collect {|rule| rule.to_posting_info(payment_transaction, payment_allocation)}
  end

  def self.load_product_accounting_rules(rules_hash)    
    rules_hash.each { |product_action, accounting|
      product_accounting_rule = first_or_create(:product_action => product_action.to_sym)
      debits = accounting['debit']
      debits.each { |product_amount, ledger_classification_text|
        ledger_classification = LedgerClassification.resolve(ledger_classification_text)
        raise Errors::InvalidConfigurationError, "No ledger classification was found for #{ledger_classification_text}" unless ledger_classification
        debit_posting_rule = ProductPostingRule.first_or_create(
            :effect => DEBIT_EFFECT,
            :product_amount => product_amount.to_sym,
            :ledger_classification => ledger_classification,
            :product_accounting_rule => product_accounting_rule
        )
        raise Errors::InvalidConfigurationError, debit_posting_rule.errors.first.first unless (debit_posting_rule and (not (debit_posting_rule.id.nil?)))
      }

      credits = accounting['credit']
      credits.each { |product_amount, ledger_classification_text|
        ledger_classification = LedgerClassification.resolve(ledger_classification_text)
        raise Errors::InvalidConfigurationError, "No ledger classification was found for #{ledger_classification_text}" unless ledger_classification
        credit_posting_rule = ProductPostingRule.first_or_create(
            :effect => CREDIT_EFFECT,
            :product_amount => product_amount.to_sym,
            :ledger_classification => ledger_classification,
            :product_accounting_rule => product_accounting_rule
        )
        raise Errors::InvalidConfigurationError, credit_posting_rule.errors.first.first unless (credit_posting_rule and (not (credit_posting_rule.id.nil?)))
      }
    }
  end
  
  def self.resolve_rule_for_product_action(product_action)
    first(:product_action => product_action.to_sym)
  end

end
