module Constants
  module MoneyConstants

    INR = :INR; USD = :USD; YEN = :JPY ; DEFAULT_CURRENCY = INR
    CURRENCIES = [ INR, USD, YEN ]

    CURRENCIES_LEAST_UNITS_MULTIPLIERS = { INR => 100, USD => 100, YEN => 1 }
    CURRENCIES_LEAST_UNITS_DECIMAL_EXPONENTS = { INR => 2, USD => 2, YEN => 0 }
    CURRENCIES_DEFAULT_DECIMAL_SEPARATORS = { INR => '.', USD => '.', YEN => '' }

  end
end