module Constants
  module Transaction

    CLIENT = :client
    COUNTERPARTIES = [CLIENT]
    COUNTERPARTIES_AND_MODELS = { CLIENT => 'Client' }
    MODELS_AND_COUNTERPARTIES = { 'Client' => CLIENT }

    COUNTERPARTY_ADMINISTERED_AT = :administered_at
    COUNTERPARTY_REGISTERED_AT   = :registered_at

    RECEIPT = :receipt; PAYMENT = :payment
    RECEIVED_OR_PAID = [RECEIPT, PAYMENT]

    LOAN_DISBURSEMENT = :loan_disbursement; 
    LOAN_REPAYMENT    = :loan_repayment;
    LOAN_ACCRUAL      = :loan_accrual
    LOAN_PRECLOSURE   = :loan_preclosure
    PRODUCT_ACTIONS   = [LOAN_DISBURSEMENT, LOAN_REPAYMENT, LOAN_ACCRUAL, LOAN_PRECLOSURE]

    FEE_CHARGED_ON_CLIENT = :fee_charged_on_client; FEE_CHARGED_ON_LOAN = :fee_charged_on_loan
    PREMIUM_COLLECTED_ON_INSURANCE = :premium_collected_on_insurance
    FEE_CHARGED_ON_TYPES = [FEE_CHARGED_ON_CLIENT, FEE_CHARGED_ON_LOAN, PREMIUM_COLLECTED_ON_INSURANCE]

    TRANSACTION_PERFORMED_AT = :transaction_performed_at
    TRANSACTION_ACCOUNTED_AT = :transaction_accounted_at
    TRANSACTION_LOCATIONS = {
      TRANSACTION_PERFORMED_AT => :performed_at,
      TRANSACTION_ACCOUNTED_AT => :accounted_at
    }

    TRANSACTED_PRODUCTS = Constants::Products::PRODUCTS

    PAYMENT_TOWARDS_LOAN_DISBURSEMENT = :payment_towards_loan_disbursement
    PAYMENT_TOWARDS_LOAN_REPAYMENT    = :payment_towards_loan_repayment
    PAYMENT_TOWARDS_LOAN_PRECLOSURE   = :payment_towards_loan_preclosure
    PAYMENT_TOWARDS_FEE_RECEIPT       = :payment_towards_fee_receipt
    PAYMENT_TOWARDS_TYPES = [
      PAYMENT_TOWARDS_LOAN_DISBURSEMENT,
      PAYMENT_TOWARDS_LOAN_REPAYMENT,
      PAYMENT_TOWARDS_LOAN_PRECLOSURE,
      PAYMENT_TOWARDS_FEE_RECEIPT
    ]

    PRINCIPAL_AMOUNT = :principal_amount; INTEREST_AMOUNT = :interest_amount
    TOTAL_PRINCIPAL_AMOUNT = :total_principal_amount; TOTAL_INTEREST_AMOUNT = :total_interest_amount

    PRINCIPAL_BALANCE_BEFORE = :principal_balance_before; INTEREST_BALANCE_BEFORE = :interest_balance_before
    PRINCIPAL_AMOUNT_DUE = :principal_amount_due; INTEREST_AMOUNT_DUE = :interest_amount_due
    PRINCIPAL_BALANCE_AFTER = :principal_balance_after; INTEREST_BALANCE_AFTER = :interest_balance_after
  end
end