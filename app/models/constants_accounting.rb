module Constants
  module Accounting

    INR = :INR; USD = :USD
    DEFAULT_CURRENCY = INR
    PLACEHOLDER_FOR_CURRENCY = :placeholder_for_currency
    CURRENCIES = [PLACEHOLDER_FOR_CURRENCY, INR, USD]

    ASSETS = :assets
    LIABILITIES = :liabilities
    INCOMES = :incomes
    EXPENSES = :expenses
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
  end
end
