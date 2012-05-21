class MoneyManager
  include Constants::Money

  # The application uses this factory to create instances of money that are all the same currency
  # defaulted from configuration
  def self.get_money_instance(*regular_amount_str)
    regular_amount_str.collect { |amount_str|
      Money.parse(get_default_currency, get_default_locale, amount_str)
    }
  end

  # Use this factory to get an instance of money in the default currency for an amount of money that is in least terms
  def self.get_money_instance_least_terms(amount_in_least_terms_int)
    Money.new(amount_in_least_terms_int, get_default_currency)
  end

  def self.get_default_currency
    ConfigurationFacade.instance.default_currency
  end

  def self.get_default_locale
    ConfigurationFacade.instance.default_locale
  end

end