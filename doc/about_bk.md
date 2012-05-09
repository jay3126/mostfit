## Overview
Work on the "bk" branch is an effort to significantly improve accounting (a.k.a book-keeping) in Mostfit
The earlier implementation is flawed, is limited in capability, and has poor documentation and test coverage. These issues are to be addressed in the current effort.

## Codebase changes

### Models added
* AccountGroup      : is a collection of accounts that belong together, such as "Current Assets"
* AccountingRule    : is used by Mostfit to determine the 'automated' accounting treatment for each kind of transaction
* BankAccountLedger : is an account that corresponds to a bank account
* CostCenter        : is used as a label to mark accounting vouchers (a.k.a journals)
* Ledger            : is the same as an account
* LedgerBalance     : is an abstraction of the balance on an account
* LedgerPosting     : is a debit or credit posting as part of a 'voucher' or 'journal entry' 
* MoneyCategory     : each MoneyCategory represents a unique form of transaction in Mostfit
* PostingRule       : is a component of AccountingRule that specifies the form of each debit or credit posting to be recorded
* TransactionSummary: represents the total value of a certain kind of transaction (as identified by MoneyCategory) for each branch
* Voucher           : is the same as a journal entry

### POROs (Plain Old Ruby Objects)
* PostingInfo           : used to communicate posting information
* TransactionSummaryInfo: used to communicate information about transaction summary instances

### Modules added
* BookKeeper            : contains methods that can be included by a concrete implementation to performs certain book-keeping tasks
* Constants::Accounting : used as a namespace to organise all constants that book-keeping references
* PostingValidator      : contains common validations that apply to instances of models such as LedgerPosting and PostingRule

### Rake tasks added
* rake mostfit:books:setup_books
* rake mostfit:books:record_transaction_summaries[<'yyyy-mm-dd'>]
* rake mostfit:books:record_vouchers[<'yyyy-mm-dd'>]

### Bootstrap configuration files
* config/account_groups.yml
* config/accounting_rules.yml
* config/accounts.yml

### Reports added
The standard accounting reports and financial statements are added:
* Journal
* DayBook
* BankBook
* TrialBalance
* BalanceSheet
* IncomeStatement

### Test coverage
* Model specs have been implemented for most models
* Factories for most models and some sequences have been added to spec/factories.rb 

### Other changes

* All constants have been namespaced using the module Constants::Accounting (app/models/constants_accounting.rb)

## Functionality

# Transaction summaries aggregate each kind of transaction at each branch on each date
# Each transaction summary corresponds to a 'money category', or one kind of transaction or accrual
# Each transaction summary is mapped using its money category to a simple accounting rule
# The ledgers, journals, and postings have been implemented for simple accounting
# The concept of cost center has been introduced to simplify accounting for transactions at branches under a single chart of accounts. This concept has to be refined to make it a per-posting cost center, rather than per-voucher
