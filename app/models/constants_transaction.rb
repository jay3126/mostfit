module Constants
  module Transaction

    CUSTOMER = :customer
    COUNTERPARTIES = [CUSTOMER]
    COUNTERPARTIES_AND_MODELS = { CUSTOMER => Customer }

    RECEIPT = :receipt; PAYMENT = :payment
    RECEIVED_OR_PAID = [RECEIPT, PAYMENT]

    TRANSACTED_PRODUCTS = Constants::Products::PRODUCTS

    PRINCIPAL_AMOUNT = :principal_amount; INTEREST_AMOUNT = :interest_amount
    TOTAL_PRINCIPAL_AMOUNT = :total_principal_amount; TOTAL_INTEREST_AMOUNT = :total_interest_amount

    PRINCIPAL_BALANCE_BEFORE = :principal_balance_before; INTEREST_BALANCE_BEFORE = :interest_balance_before
    PRINCIPAL_AMOUNT_DUE = :principal_amount_due; INTEREST_AMOUNT_DUE = :interest_amount_due
    PRINCIPAL_BALANCE_AFTER = :principal_balance_after; INTEREST_BALANCE_AFTER = :interest_balance_after
  end
end