class Ledger
  include DataMapper::Resource
  include Constants::Accounting

# Ledger represents an account, and is a basic building-block for book-keeping
# Ledgers are classified into one of four 'account types': Assets, Liabilities, Incomes, and Expenses
# Ledgers can also be 'grouped' under an AccountGroup, primarily for standardised reporting of financial statements
# A ledger must report a "balance" at every point in time since it comes into existence
# The balance that is associated with the ledger when it is first created represents its (earliest) opening balance
# Ledger also serves as the base class for certain 'special' kinds of accounts (such as BankAccountLedger)

  property :id,                       Serial
  property :name,                     String, :nullable => false
  property :account_type,             Enum.send('[]', *ACCOUNT_TYPES), :nullable => false
  property :open_on,                  Date, :nullable => false
  property :opening_balance_amount,   Float, :nullable => false, :default => 0
  property :opening_balance_currency, Enum.send('[]', *CURRENCIES), :nullable => false, :default => DEFAULT_CURRENCY
  property :opening_balance_effect,   Enum.send('[]', *ACCOUNTING_EFFECTS), :nullable => false
  property :created_at,               DateTime, :nullable => false, :default => DateTime.now
  property :type,                     Discriminator

  has n, :ledger_postings
  has n, :posting_rules
  belongs_to :account_group, :nullable => true
  belongs_to :accounts_chart

  validates_present :name, :account_type, :open_on, :opening_balance_amount, :opening_balance_currency, :opening_balance_effect

  # Returns the opening balance, and the date on which such opening balance was set for the account
  def opening_balance_and_date
    [LedgerBalance.to_balance_obj(opening_balance_amount, opening_balance_currency, opening_balance_effect), open_on]
  end
  
  # Returns the balance for the ledger on a specified date
  # If such date is before the date that the account is 'open', the balance is nil
  def balance(on_date = Date.today, cost_center = nil)
    opening_balance, open_date = opening_balance_and_date
    return nil if on_date < open_date
    
    postings = Voucher.get_postings(self, cost_center, on_date)
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
          :opening_balance_amount => opening_balance_amount, :opening_balance_currency => opening_balance_currency, :opening_balance_effect => opening_balance_effect)
      }
    }
  end

end

class BankAccountLedger < Ledger

  validates_with_method :is_asset_type?

  def is_asset_type?
  	account_type == ASSETS ? true : [false, "bank account ledgers must be set to account type #{ASSETS}"]
  end

end
