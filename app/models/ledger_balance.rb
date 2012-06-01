class LedgerBalance
  include Constants::Accounting, Constants::Money

  attr_reader :amount, :currency, :effect

  def initialize(amount, currency, effect)
    valid, message = LedgerBalance.valid_balance?(amount, currency, effect)
    raise ArgumentError, message unless valid
    @amount = amount
    @currency = currency
    @effect = effect
  end

  def to_s
    "#{@amount} #{@currency} #{@effect}"
  end
  
  def ==(other)
    return false unless (other and other.is_a?(LedgerBalance))
    return false unless other.currency == self.currency
    return false unless other.effect == self.effect
    other.amount == self.amount
  end
  
  alias eql? ==

  def self.to_balance_obj(amount, currency, effect)
    new(amount, currency, effect)
  end
  
  def self.zero_balance(currency, effect)
    to_balance_obj(0, currency, effect)
  end

  # Tests a balance to verify whether it is a zero balance (irrespective of the balance 'effect')
  def self.is_zero_balance?(some_balance)
    raise ArgumentError, "#{some_balance} is not a ledger balance" unless some_balance.is_a?(LedgerBalance)
    some_balance.amount == 0
  end
  
  def self.zero_debit_balance(currency); zero_balance(currency, DEBIT_EFFECT); end
  def self.zero_credit_balance(currency); zero_balance(currency, CREDIT_EFFECT); end  

  def is_debit_balance?; effect == DEBIT_EFFECT; end
  def is_credit_balance?; !(is_debit_balance?); end

  def get_debit_balance; is_debit_balance? ? self : nil; end
  def get_credit_balance; is_credit_balance? ? self : nil; end

  def +(other)
    validity, message = LedgerBalance.valid_balance_obj?(other)
    raise ArgumentError, message unless validity
    can_add, message = LedgerBalance.can_add?(self, other)
    raise ArgumentError, message unless can_add
    return self if other.amount == 0
    return other if self.amount == 0
    same_effect = self.effect == other.effect
    if same_effect
      return LedgerBalance.to_balance_obj(self.amount + other.amount, self.currency, self.effect)
    else
      net_effect = (self.amount >= other.amount) ? self.effect : other.effect
      return LedgerBalance.to_balance_obj((self.amount - other.amount).abs, self.currency, net_effect)
    end
  end
  
  def balance
    [@amount, @currency, @effect]
  end

  def self.valid_balance?(amount, currency, effect)
    return [false, "amount, currency, and effect are all required"] unless (amount and currency and effect)
    return [false, "does not accept negative amounts: #{amount}"] if (amount < 0)
    return [false, "does not accept this currency: #{currency}"] unless CURRENCIES.include?(currency)
    return [false, "does not accept this effect: #{effect}"] unless ACCOUNTING_EFFECTS.include?(effect)
    true
  end
  
  def self.valid_balance_obj?(balance_obj)
    return [false, "The value is either nil or not an accounting balance"] unless (balance_obj and 
      balance_obj.respond_to?(:amount) and balance_obj.respond_to?(:currency) and balance_obj.respond_to?(:effect))
    valid_balance?(balance_obj.amount, balance_obj.currency, balance_obj.effect)
  end
  
  def self.validate_balances(*balances)
    raise ArgumentError, balances unless balances
    balances.each { |bal|
      valid, message = valid_balance_obj?(bal)
      return [valid, message] unless valid
    }
    true
  end
  
  def self.can_add?(foo, bar)
    return [false, "balances use multiple currencies and are not currently supported for addition"] unless foo.currency == bar.currency
    true
  end
  
  def self.can_add_balances?(*balances)
    currencies = balances.collect { |bal| bal.currency }
    unique_currencies = currencies.uniq
    return [false, "balances use multiple currencies and are not currently supported for addition: #{unique_currencies}"] unless (unique_currencies.count == 1)
    true
  end
  
  def self.add_balances(*balances)
    validity, message = can_add_balances?(*balances)
    return [validity, message] unless validity 
    add_fast(*balances)
    #balances.inject { |sum, bal| sum += bal }
  end
  
  def self.are_balanced?(*balances)
    sum_of_balances = add_balances(*balances)
    sum_of_balances.amount == 0
  end

  private

  def self.add_fast(*balances)
    sum_of_debits = 0; sum_of_credits = 0
    balances.each { |bal| 
      case bal.effect
      when DEBIT_EFFECT then sum_of_debits += bal.amount
      when CREDIT_EFFECT then sum_of_credits += bal.amount
      else raise ArgumentError, "invalid accounting effect: #{bal.effect}"
      end
    }
    currency = balances.first.currency
    debit_sum_balance = to_balance_obj(sum_of_debits, currency, DEBIT_EFFECT)
    credit_sum_balance = to_balance_obj(sum_of_credits, currency, CREDIT_EFFECT)
    debit_sum_balance + credit_sum_balance
  end

end