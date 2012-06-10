class Ledger
  include DataMapper::Resource
  include Constants::Properties, Constants::Accounting, Constants::Money

# Ledger represents an account, and is a basic building-block for book-keeping
# Ledgers are classified into one of four 'account types': Assets, Liabilities, Incomes, and Expenses
# Ledgers can also be 'grouped' under an AccountGroup, primarily for standardised reporting of financial statements
# A ledger must report a "balance" at every point in time since it comes into existence
# The balance that is associated with the ledger when it is first created represents its (earliest) opening balance
# Ledger also serves as the base class for certain 'special' kinds of accounts (such as BankAccountLedger)

  property :id,                       Serial
  property :name,                     String, :length => 1024, :nullable => false
  property :account_type,             Enum.send('[]', *ACCOUNT_TYPES), :nullable => false
  property :open_on,                  *DATE_NOT_NULL
  property :opening_balance_amount,   *MONEY_AMOUNT
  property :opening_balance_currency, *CURRENCY
  property :opening_balance_effect,   Enum.send('[]', *ACCOUNTING_EFFECTS), :nullable => false
  property :created_at,               *CREATED_AT
  property :type,                     Discriminator

  has n, :ledger_postings
  has n, :posting_rules
  belongs_to :account_group, :nullable => true
  belongs_to :accounts_chart
  belongs_to :ledger_classification, :nullable => true
  belongs_to :ledger_assignment, :nullable => true

  def money_amounts; [ :opening_balance_amount ]; end

  validates_present :name, :account_type, :open_on, :opening_balance_amount, :opening_balance_currency, :opening_balance_effect

  # Returns the opening balance, and the date on which such opening balance was set for the account
  def opening_balance_and_date
    [LedgerBalance.to_balance_obj(opening_balance_amount, opening_balance_currency, opening_balance_effect), open_on]
  end
  
  # Returns the balance for the ledger on a specified date
  # If such date is before the date that the account is 'open', the balance is nil
  def balance(on_date = Date.today)
    opening_balance, open_date = opening_balance_and_date
    return nil if on_date < open_date
    
    postings = Voucher.get_postings(self, on_date)
    LedgerBalance.add_balances(opening_balance, *postings)
  end

  # Returns the opening balance on the ledger on a given date
  # The opening balance is the balance computed on the ledger before any new entries have been posted to it on the date
  def opening_balance(on_date = Date.today)
    opening_balance, open_date = opening_balance_and_date
    return nil if on_date < open_date
    return opening_balance if on_date == open_date
    previous_day = on_date - 1
    balance(previous_day)
  end

  # Given a hash of accounts (such as one read from a .yml configuration file), this method creates a basic set of ledgers
  def self.load_accounts_chart(chart_hash)
    account_types_and_ledgers = {}
    opening_balance_amount, opening_balance_currency = 0, DEFAULT_CURRENCY

    chart_name = chart_hash['chart']['name']
    chart_type = chart_hash['chart']['chart_type']
    chart = AccountsChart.first_or_create(:name => chart_name, :chart_type => chart_type)

    ACCOUNT_TYPES.each { |type|
      ledgers = chart_hash['chart'][type.to_s]
      account_types_and_ledgers[type] = ledgers
    }
    open_on = chart_hash['open_on']
    
    account_types_and_ledgers.each { |type, ledgers|
      type_sym = type.to_sym
      opening_balance_effect = DEFAULT_EFFECTS_BY_TYPE[type_sym]
      ledgers.each { |account_name|
        Ledger.first_or_create(:name => account_name, :account_type => type_sym, :open_on => open_on, 
          :opening_balance_amount => opening_balance_amount, :opening_balance_currency => opening_balance_currency, :opening_balance_effect => opening_balance_effect, :accounts_chart => chart)
      }
    }
  end

  def self.setup_product_ledgers(with_accounts_chart, currency, open_on_date, for_product_type = nil, for_product_id = nil)
    all_product_ledgers = {}
    PRODUCT_LEDGER_TYPES.each { |product_ledger_type|
      ledger_classification = LedgerClassification.resolve(product_ledger_type)
      ledger_product_type, ledger_product_id = ledger_classification.is_product_specific ? [for_product_type, for_product_id] : 
          [nil, nil]

      ledger_assignment = LedgerAssignment.record_ledger_assignment(with_accounts_chart, ledger_classification, ledger_product_type, ledger_product_id)
      ledger_name = name_for_product_ledger(with_accounts_chart.counterparty_type, with_accounts_chart.counterparty_id, ledger_classification, ledger_product_type, ledger_product_id)
      account_type = ledger_classification.account_type
      
      ledger = {}
      ledger[:name] = ledger_name
      ledger[:account_type] = account_type
      ledger[:open_on] = open_on_date
      ledger[:opening_balance_amount] = 0
      ledger[:opening_balance_currency] = currency
      ledger[:opening_balance_effect] = DEFAULT_EFFECTS_BY_TYPE[account_type]
      ledger[:accounts_chart] = with_accounts_chart
      ledger[:ledger_classification] = ledger_classification
      ledger[:ledger_assignment] = ledger_assignment
      product_ledger = first_or_create(ledger)
      raise Errors::DataError, product_ledger.errors.first.first if product_ledger.id.nil?
      all_product_ledgers[ledger_classification.account_purpose] = product_ledger
    }
    all_product_ledgers
  end

  def self.name_for_product_ledger(counterparty_type, counterparty_id, ledger_classification, product_type = nil, product_id = nil)
    name = "#{ledger_classification} #{counterparty_type}: #{counterparty_id}"
    name += " for #{product_type}: #{product_id}" if (product_type and product_id)
    name
  end

end

class BankAccountLedger < Ledger

  validates_with_method :is_asset_type?

  def is_asset_type?
  	account_type == ASSETS ? true : [false, "bank account ledgers must be set to account type #{ASSETS}"]
  end

end
