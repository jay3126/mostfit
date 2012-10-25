module Constants
  module Accounting

    ASSETS = :assets
    LIABILITIES = :liabilities
    INCOMES = :incomes
    EXPENSES = :expenses
    RECEIPT = :receipt
    PAYMENT = :payment
    LEDGER = :ledger
    PRODUCT_LOCATION = [LEDGER]
    VOUCHER_TYPE = [RECEIPT, PAYMENT]
    ACCOUNT_TYPES = [ASSETS, LIABILITIES, INCOMES, EXPENSES]
    ACCOUNT_TYPES_MENU_CHOICES = ACCOUNT_TYPES.collect {|type| [type.to_s, type]}

    DEBIT_EFFECT = :debit
    CREDIT_EFFECT = :credit
    ACCOUNTING_EFFECTS = [DEBIT_EFFECT, CREDIT_EFFECT]
    ACCOUNTING_EFFECTS_MENU_CHOICES = ACCOUNTING_EFFECTS.collect {|effect| [effect.to_s, effect]}
 
    DEFAULT_EFFECTS_BY_TYPE = {
      ASSETS => DEBIT_EFFECT, EXPENSES => DEBIT_EFFECT,
      LIABILITIES => CREDIT_EFFECT, INCOMES => CREDIT_EFFECT
    }   

    DEFAULT_HEAD_OFFICE_COST_CENTER_NAME = "Head Office"

    MANUAL_VOUCHER = :manual_voucher 
    GENERATED_VOUCHER = :generated_voucher 
    VOUCHER_MODES = [MANUAL_VOUCHER, GENERATED_VOUCHER]

    TRANSACTION = :transaction; ACCRUAL = :accrual
    TRANSACTED_CATEGORIES = [TRANSACTION, ACCRUAL]

    TO_PAY = :to_pay; TO_RECEIVE = :to_receive
    RECEIVABLE_CATEGORIES = [TO_PAY, TO_RECEIVE]
    
    NOT_AN_ASSET = :not_an_asset; LOANS_MADE = :loans_made; DEPOSITS_MADE = :deposits_made
    ASSET_CATEGORIES = [NOT_AN_ASSET, LOANS_MADE, DEPOSITS_MADE]

    NOT_A_LIABILITY = :not_a_liability; LOANS_TAKEN = :loans_taken; DEPOSITS_ACCEPTED = :deposits_accepted; ADVANCE_RECEIVED = :advance_received
    LIABILITY_CATEGORIES = [NOT_A_LIABILITY, LOANS_TAKEN, DEPOSITS_ACCEPTED, ADVANCE_RECEIVED]

    NOT_AN_INCOME = :not_an_income; INTEREST_INCOME_FROM_LOANS = :interest_income_from_loans; FEE_INCOME_FROM_LOANS = :fee_income_from_loans; OTHER_FEE_INCOME = :other_fee_income; COMMISSIONS_INCOME = :commissions_income
    INCOME_CATEGORIES = [NOT_AN_INCOME, INTEREST_INCOME_FROM_LOANS, FEE_INCOME_FROM_LOANS, OTHER_FEE_INCOME, COMMISSIONS_INCOME]

    NOT_AN_EXPENSE = :not_an_expense; INTEREST_EXPENSE = :interest_expense; FEE_EXPENSE = :fee_expense; COMMISSIONS_EXPENSE = :commissions_expense
    EXPENSE_CATEGORIES = [NOT_AN_EXPENSE, INTEREST_EXPENSE, FEE_EXPENSE, COMMISSIONS_EXPENSE]

    NOT_A_VALID_ASSET_TYPE_ID = -1
    NOT_A_VALID_INCOME_TYPE_ID = -1

    OWNED = :owned; NOT_OWNED = :not_owned
    OWNED_CATEGORIES = [OWNED, NOT_OWNED]

    NOT_REVERSED = false
    REVERSED = true

    LOAN_DISBURSEMENT = :loan_disbursement 
    PRINCIPAL_REPAID_RECEIVED_ON_LOANS_MADE = :principal_repaid_received_on_loans_made 
    INTEREST_RECEIVED_ON_LOANS_MADE = :interest_received_on_loans_made; 
    FEE_RECEIVED_ON_LOANS_MADE = :fee_received_on_loans_made
    OTHER_FEE_RECEIVED_SPECIFIC = :other_fee_received_specific

    SCHEDULED_DISBURSEMENTS_OF_LOANS = :scheduled_disbursements_of_loans
    ACCRUE_REGULAR_PRINCIPAL_REPAYMENTS_ON_LOANS = :accrue_regular_principal_repayments_on_loans
    ACCRUE_REGULAR_INTEREST_RECEIPTS_ON_LOANS = :accrue_regular_interest_receipts_on_loans
    ACCRUE_BROKEN_PERIOD_INTEREST_RECEIPTS_ON_LOANS = :accrue_broken_period_interest_receipts_on_loans 
    ACCRUE_NEW_PERIOD_REVERSALS_OF_BROKEN_PERIOD_INTEREST_RECEIPTS = :accrue_new_period_reversals_of_broken_period_interest_receipts

    PRODUCT_ACCOUNTING = :product_accounting; FINANCIAL_ACCOUNTING = :financial_accounting
    ACCOUNTS_CHART_TYPES = [PRODUCT_ACCOUNTING, FINANCIAL_ACCOUNTING]

    CUSTOMER_CASH                  = :customer_cash
    CUSTOMER_FEE_RECEIPT           = :customer_fee_receipt
    CUSTOMER_LOAN_DISBURSED        = :customer_loan_disbursed
    CUSTOMER_LOAN_REPAID           = :customer_loan_repaid
    CUSTOMER_LOAN_ADVANCE_RECEIPT  = :customer_loan_advance_receipt
    CUSTOMER_LOAN_INTEREST_RECEIPT = :customer_loan_interest_receipt
    CUSTOMER_LOAN_FEE_RECEIPT      = :customer_loan_fee_receipt
    CUSTOMER_LOAN_DEBTORS          = :customer_loan_debtors
    CUSTOMER_LOAN_OTHER_INCOME     = :customer_loan_other_income
    CUSTOMER_BANK_ACCOUNT          = :customer_bank
    CUSTOMER_LOAN_WRITE_OFF        = :customer_loan_write_off

    DEFAULT_LEDGERS = {CUSTOMER_CASH => 'Cash', CUSTOMER_BANK_ACCOUNT => 'Bank Account', CUSTOMER_LOAN_FEE_RECEIPT => 'Charges Income', CUSTOMER_LOAN_DISBURSED => 'Loans Made', CUSTOMER_LOAN_ADVANCE_RECEIPT => 'Loans Advance', CUSTOMER_LOAN_INTEREST_RECEIPT => 'Interest Income',
      CUSTOMER_LOAN_DEBTORS => 'Debtors', CUSTOMER_LOAN_OTHER_INCOME => 'Other Income', CUSTOMER_LOAN_WRITE_OFF => 'Loans Write Off'}

    CUSTOMER_SPECIFIC_LEDGER_TYPES = [CUSTOMER_CASH, CUSTOMER_BANK_ACCOUNT]
    CUSTOMER_LOAN_PRODUCT_SPECIFIC_LEDGER_TYPES = [CUSTOMER_LOAN_DISBURSED, CUSTOMER_LOAN_REPAID, CUSTOMER_LOAN_ADVANCE_RECEIPT, CUSTOMER_LOAN_INTEREST_RECEIPT, CUSTOMER_LOAN_FEE_RECEIPT, CUSTOMER_LOAN_DEBTORS, CUSTOMER_LOAN_OTHER_INCOME, CUSTOMER_LOAN_WRITE_OFF]

    ACCRUE_PRINCIPAL_ALLOCATION = :accrue_principal_allocation
    ACCRUE_INTEREST_ALLOCATION  = :accrue_interest_allocation
    ACCRUE_REGULAR              = :accrue_regular
    ACCRUE_BROKEN_PERIOD        = :accrue_broken_period
    REVERSE_BROKEN_PERIOD_ACCRUAL = :reverse_broken_period_accrual

    ACCRUAL_ALLOCATION_TYPES = [ACCRUE_PRINCIPAL_ALLOCATION, ACCRUE_INTEREST_ALLOCATION]
    ACCRUAL_TEMPORAL_TYPES   = [ACCRUE_REGULAR, ACCRUE_BROKEN_PERIOD, REVERSE_BROKEN_PERIOD_ACCRUAL]

    LOAN_ACCRUE_REGULAR_PRINCIPAL = :loan_accrue_regular_principal
    LOAN_ACCRUE_REGULAR_INTEREST  = :loan_accrue_regular_interest
    LOAN_ACCRUE_BROKEN_PERIOD_INTEREST = :loan_accrue_broken_period_interest
    LOAN_ACCRUE_BROKEN_PERIOD_INTEREST_REVERSAL = :loan_accrue_broken_period_interest_reversal

    LOAN_ACCRUAL_PRODUCT_ACTIONS = [LOAN_ACCRUE_REGULAR_PRINCIPAL, LOAN_ACCRUE_REGULAR_INTEREST, LOAN_ACCRUE_BROKEN_PERIOD_INTEREST, LOAN_ACCRUE_BROKEN_PERIOD_INTEREST_REVERSAL]

    PRODUCT_ACTIONS_FOR_ACCRUAL_TRANSACTIONS = {
      Constants::Products::LENDING => {
        ACCRUE_REGULAR => {
          ACCRUE_PRINCIPAL_ALLOCATION => LOAN_ACCRUE_REGULAR_PRINCIPAL,
          ACCRUE_INTEREST_ALLOCATION  => LOAN_ACCRUE_REGULAR_INTEREST
        },
        ACCRUE_BROKEN_PERIOD => {
          ACCRUE_INTEREST_ALLOCATION  => LOAN_ACCRUE_BROKEN_PERIOD_INTEREST
        },
        REVERSE_BROKEN_PERIOD_ACCRUAL => {
          ACCRUE_INTEREST_ALLOCATION  => LOAN_ACCRUE_BROKEN_PERIOD_INTEREST_REVERSAL
        }
      }
    }

    PRODUCT_LEDGER_TYPES = (CUSTOMER_SPECIFIC_LEDGER_TYPES + CUSTOMER_LOAN_PRODUCT_SPECIFIC_LEDGER_TYPES).flatten

    CUSTOMER_LEDGER_CLASSIFICATION = {
      CUSTOMER_CASH => ASSETS,
      CUSTOMER_BANK_ACCOUNT => ASSETS,
      CUSTOMER_LOAN_DISBURSED => ASSETS,
      CUSTOMER_LOAN_DEBTORS => ASSETS,
      CUSTOMER_LOAN_REPAID => ASSETS,
      CUSTOMER_LOAN_WRITE_OFF => ASSETS,
      CUSTOMER_LOAN_ADVANCE_RECEIPT => LIABILITIES,
      CUSTOMER_LOAN_INTEREST_RECEIPT => INCOMES,
      CUSTOMER_LOAN_FEE_RECEIPT => INCOMES,
      CUSTOMER_LOAN_OTHER_INCOME => INCOMES
    }

    NOT_APPLICABLE = :not_applicable
    LEDGER_ASSIGNMENT_PRODUCT_TYPES = ([NOT_APPLICABLE] + Constants::Transaction::TRANSACTED_PRODUCTS).flatten

    NOT_SPECIFIED = :not_specified
    ACCOUNTING_COUNTERPARTIES = ([NOT_SPECIFIED] + Constants::Transaction::COUNTERPARTIES).flatten

    PRODUCT_AMOUNTS = Constants::LoanAmounts::LOAN_PRODUCT_AMOUNTS
    MONEY_DEPOSIT = :money_deposit
    LOAN_DUE = :loan_due
    WRITE_OFF = :write_off
    PRODUCT_ACTIONS = Constants::Transaction::PRODUCT_ACTIONS + LOAN_ACCRUAL_PRODUCT_ACTIONS + [MONEY_DEPOSIT, LOAN_DUE, WRITE_OFF]

    PRODUCT_ACTIONS_FOR_PAYMENT_TRANSACTIONS = {
      Constants::Products::LENDING => {

        Constants::Transaction::RECEIPT =>
          { 
          Constants::Transaction::PAYMENT_TOWARDS_LOAN_REPAYMENT  => Constants::Transaction::LOAN_REPAYMENT,
          Constants::Transaction::PAYMENT_TOWARDS_LOAN_PRECLOSURE => Constants::Transaction::LOAN_PRECLOSURE,
          Constants::Transaction::PAYMENT_TOWARDS_LOAN_RECOVERY   => Constants::Transaction::LOAN_RECOVERY,
          Constants::Transaction::PAYMENT_TOWARDS_FEE_RECEIPT    => Constants::Transaction::LOAN_FEE_RECEIPT
        },

        Constants::Transaction::PAYMENT =>
          { Constants::Transaction::PAYMENT_TOWARDS_LOAN_DISBURSEMENT => Constants::Transaction::LOAN_DISBURSEMENT},

        Constants::Transaction::CONTRA  =>
          { Constants::Transaction::PAYMENT_TOWARDS_LOAN_ADVANCE_ADJUSTMENT => Constants::Transaction::LOAN_ADVANCE_ADJUSTMENT}
        
      }
    }

    PRODUCT_ACCOUNTING = :product_accounting
    FINANCIAL_ACCOUNTING = :financial_accounting
    ACCOUNTING_MODES = [ PRODUCT_ACCOUNTING, FINANCIAL_ACCOUNTING ]

    PAYMENT_TRANSACTION_TYPE = :payment_transaction_type
    ACCRUAL_TRANSACTION_TYPE = :accrual_transaction_type
    ACCOUNTS_FOR_TRANSACTION_TYPES = [PAYMENT_TRANSACTION_TYPE, ACCRUAL_TRANSACTION_TYPE]
  end
end
