class Money
  include Constants::Money
  include Comparable

  attr_reader :amount, :currency

  # Create new instances of money
  # Supply a non-negative amount in 'least' units, and a currency that is already configured
  def initialize(amount, currency)
    raise ArgumentError, "#{currency} is not currently supported" unless CURRENCIES.include?(currency)
    raise ArgumentError, "#{amount} is not valid" unless (amount.is_a?(Integer) and amount >= 0)
    @amount = amount; @currency = currency
  end

  # Get a new instance of money
  # Supply the currency, locale, and the regular amount as a string
  # TODO: parsing for the particular locale is pending
  def self.parse(currency, locale, regular_amount_str)
    amount_in_least_terms = regular_to_least_amount(regular_amount_str, locale, currency)
    new(amount_in_least_terms, currency)
  end

  # Returns a money with zero value that can be used as a datum for money operations
  def self.zero_money_amount(in_currency)
    new(0, in_currency)
  end

  # Two instances of money are only equal, if and only if both amount and currency are the same
  def ==(other)
    return false unless other.is_a?(Money)
    ((self.amount == other.amount) and (self.currency == other.currency))
  end

  alias eql? ==

  # Money amounts in the same currency compare by amount
  def <=>(other)
    other.is_a?(Money) ? (other.currency == self.currency ? self.amount <=> other.amount : nil) : nil
  end

  # Two money instances can only be added together if they are the same currency
  # They are added by taking the simple arithmetic sum of their amounts and preserving the currency
  def +(other)
    raise TypeError, "#{other} is not money" unless other.is_a?(Money)
    raise ArgumentError, "cannot add mismatched currency #{other.currency}" unless (self.currency == other.currency)
    Money.new(self.amount + other.amount, self.currency)
  end

  # Two money instances can be subtracted, one from another, if they are the same currency
  # The difference of two money instances is the absolute difference of their amounts in the same currency
  def -(other)
    raise TypeError, "#{other} is not money" unless other.is_a?(Money)
    raise ArgumentError, "cannot add mismatched currency #{other.currency}" unless (self.currency == other.currency)
    Money.new((self.amount - other.amount).abs, self.currency)
  end

  # The string representation of Money as an amount in regular units and the currency
  def to_s
    "#{Money.format_decimal_places(@amount, @currency)} #{@currency}"
  end

  # Use this to parse a money amount in regular units as a string
  # for the given locale and currency to return a money amount in least terms
  # TODO: Implement parsing using the separators and other considerations for the
  # locale
  def self.regular_to_least_amount(regular_amount_str, locale, currency)
    parse_str = regular_amount_str.to_s
    raise ArgumentError, "#{regular_amount_str} is invalid" if (parse_str.empty?)
    raise ArgumentError, "#{currency} is not supported" unless CURRENCIES.include?(currency)

    decimal_separator = CURRENCIES_DEFAULT_DECIMAL_SEPARATORS[currency]
    raise StandardError, "decimal separator not found for #{currency}" unless decimal_separator

    decimal_exponent = CURRENCIES_LEAST_UNITS_DECIMAL_EXPONENTS[currency]
    raise StandardError, "decimal exponent not found for #{currency}" unless decimal_exponent

    partitioned_string = parse_str.partition(decimal_separator)
    
    whole_number_str = partitioned_string.first
    decimal_number_str = partitioned_string.last

    decimal_number_correct_places = decimal_number_str
    unless (decimal_separator.empty? or (decimal_exponent == 0))
      decimal_number_justified = decimal_number_str.ljust(decimal_exponent, '0')
      decimal_number_correct_places = decimal_number_justified.slice(0, decimal_exponent)
    end
    
    (whole_number_str + decimal_number_correct_places).to_i
  end

  # Given a hash that has keys as symbols for the amounts and values as instances of Money,
  # this returns a hash with keys and numeric amounts with an added key and value for currency, and
  # aids construction of new instances of models that store amounts
  def self.from_money(money_hash)
    amounts_hash = {}
    money_hash.each { |key, value|
      raise ArgumentError, "#{value} is not a money amount" unless value.is_a?(Money)
      amounts_hash[key] = value.amount
    }
    currency = money_hash.values.first.currency
    amounts_hash[:currency] = currency
    amounts_hash
  end

  private

  # Formats the money amount in least units for the given locale
  # TODO: Implement formatting using separators for the locale
  def self.format_decimal_places(amount_in_least_units, currency, locale = nil)
    decimal_exponent = CURRENCIES_LEAST_UNITS_DECIMAL_EXPONENTS[currency]
    raise StandardError, "decimal exponent not found for #{currency}" unless decimal_exponent

    decimal_separator = CURRENCIES_DEFAULT_DECIMAL_SEPARATORS[currency]
    raise StandardError, "decimal separator not found for #{currency}" unless decimal_separator

    return amount_in_least_units.to_s if (decimal_separator.empty? or (decimal_exponent == 0))

    separator_at_position = -(decimal_exponent + 1)
    amount_in_least_units.to_s.insert(separator_at_position, decimal_separator)
  end

end