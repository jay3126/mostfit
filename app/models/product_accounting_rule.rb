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
        ProductPostingRule.first_or_create(
            :effect => DEBIT_EFFECT,
            :product_amount => product_amount.to_sym,
            :ledger_classification => ledger_classification,
            :product_accounting_rule => product_accounting_rule
        )
      }

      credits = accounting['credit']
      credits.each { |product_amount, ledger_classification_text|
        ledger_classification = LedgerClassification.resolve(ledger_classification_text)
        raise Errors::InvalidConfigurationError, "No ledger classification was found for #{ledger_classification_text}" unless ledger_classification
        ProductPostingRule.first_or_create(
            :effect => CREDIT_EFFECT,
            :product_amount => product_amount.to_sym,
            :ledger_classification => ledger_classification,
            :product_accounting_rule => product_accounting_rule
        )
      }
    }
  end
  
  def self.resolve_rule_for_product_action(product_action)
    first(:product_action => product_action.to_sym)
  end

end
