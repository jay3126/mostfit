module Constants
  module Money

    INR = :INR; USD = :USD; YEN = :JPY ; DEFAULT_CURRENCY = INR
    CURRENCIES = [ INR, USD, YEN ]

    CURRENCIES_LEAST_UNITS_MULTIPLIERS = { INR => 100, USD => 100, YEN => 1 }
    CURRENCIES_LEAST_UNITS_DECIMAL_EXPONENTS = { INR => 2, USD => 2, YEN => 0 }
    CURRENCIES_DEFAULT_DECIMAL_SEPARATORS = { INR => '.', USD => '.', YEN => '' }

    PAYMENT = :payment; RECEIPT = :receipt
    RECEIVED_OR_PAID = [RECEIPT, PAYMENT]

    CLIENT = :client
    COUNTERPARTIES = [CLIENT]

    PRINCIPAL_DISBURSED = :principal_disbursed
    PRINCIPAL_REPAID = :principal_repaid; INTEREST_RECEIVED = :interest_received; FEE_INCOME = :fee_income; ADVANCE_RECEIPT = :advance_receipt
    ALLOCATIONS = [PRINCIPAL_DISBURSED, PRINCIPAL_REPAID, INTEREST_RECEIVED, FEE_INCOME, ADVANCE_RECEIPT]

  end
end