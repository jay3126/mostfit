class Ledger
  include DataMapper::Resource
  include Constants::Properties, Constants::Accounting, Constants::Money, Constants::Transaction, Identified

  # Ledger represents an account, and is a basic building-block for book-keeping
  # Ledgers are classified into one of four 'account types': Assets, Liabilities, Incomes, and Expenses
  # Ledgers can also be 'grouped' under an AccountGroup, primarily for standardised reporting of financial statements
  # A ledger must report a "balance" at every point in time since it comes into existence
  # The balance that is associated with the ledger when it is first created represents its (earliest) opening balance
  # Ledger also serves as the base class for certain 'special' kinds of accounts (such as BankAccountLedger)

  property :id,                       Serial
  property :name,                     String, :length => 1024, :nullable => false
  property :account_type,             Enum.send('[]', *ACCOUNT_TYPES), :nullable => false
  property :open_on,                  *DATE_NOT_NULL
  property :opening_balance_amount,   *MONEY_AMOUNT
  property :opening_balance_currency, *CURRENCY
  property :opening_balance_effect,   Enum.send('[]', *ACCOUNTING_EFFECTS), :nullable => false
  property :manual_voucher_permitted, Boolean, :default => false
  property :created_at,               *CREATED_AT
  property :type,                     Discriminator

  has n, :ledger_postings
  has n, :posting_rules
  has n, :vouchers, :through => :ledger_postings
  belongs_to :account_group, :nullable => true
  belongs_to :accounts_chart
  belongs_to :ledger_classification, :nullable => true
  belongs_to :ledger_assignment, :nullable => true

  def money_amounts; [ :opening_balance_amount ]; end
  def created_on; self.open_on; end

  validates_present :name, :account_type, :open_on, :opening_balance_amount, :opening_balance_currency, :opening_balance_effect

  # Returns the opening balance, and the date on which such opening balance was set for the account
  def opening_balance_and_date(cost_center_id = nil)
    [LedgerBalance.to_balance_obj(opening_balance_amount, opening_balance_currency, opening_balance_effect), open_on]
  end
  
  # Returns the balance for the ledger on a specified date
  # If such date is before the date that the account is 'open', the balance is nil
  def balance(on_date = Date.today, cost_center_id = nil)
    opening_balance, open_date = opening_balance_and_date
    cost_center_postings = []
    return nil if on_date < open_date
    
    postings = Voucher.get_postings(self, on_date)
    if cost_center_id.blank?
      cost_center_postings = postings
    else
      biz_location = CostCenter.get(cost_center_id).biz_location
      biz_location_id = biz_location.blank? ? nil : biz_location.id
      postings.group_by{|posting| posting.voucher}.each do |voucher, postings|
        cost_center_postings << postings if !postings.blank? && postings.map(&:accounted_at).include?(biz_location_id)
      end
      cost_center_postings.flatten!
    end
    LedgerBalance.add_balances(opening_balance, *cost_center_postings)
  end

  # Returns the opening balance on the ledger on a given date
  # The opening balance is the balance computed on the ledger before any new entries have been posted to it on the date
  def opening_balance(on_date = Date.today, cost_center_id = nil)
    opening_balance, open_date = opening_balance_and_date
    return nil if on_date < open_date
    return opening_balance if on_date == open_date
    previous_day = on_date - 1
    balance(previous_day, cost_center_id)
  end

  # Given a hash of accounts (such as one read from a .yml configuration file), this method creates a basic set of ledgers
  def self.load_accounts_chart(chart_hash)
    account_types_and_ledgers = {}
    opening_balance_amount, opening_balance_currency = 0, DEFAULT_CURRENCY

    chart_name = chart_hash['chart']['name']
    chart_type = chart_hash['chart']['chart_type']
    chart = AccountsChart.first_or_create(:name => chart_name, :chart_type => chart_type)
    ACCOUNT_TYPES.each { |type|
      ledgers = chart_hash['chart'][type.to_s]
      account_types_and_ledgers[type] = ledgers
    }
    open_on = chart_hash['open_on']
    cost_center = CostCenter.first(:name => 'Head Office')
    recorded_by = User.first.id
    performed_by = User.first.staff_member.id
    account_types_and_ledgers.each { |type, ledgers|
      type_sym = type.to_sym
      opening_balance_effect = DEFAULT_EFFECTS_BY_TYPE[type_sym]
      ledgers.each { |account_name|
        classification = DEFAULT_LEDGERS.index(account_name)
        ledger_classification = classification.blank? ? '' : LedgerClassification.resolve(classification)
        ledger_classification_id = ledger_classification.blank? ? nil : ledger_classification.id
        ledger = Ledger.first_or_create(:name => account_name, :account_type => type_sym, :open_on => open_on, :manual_voucher_permitted => true,
          :opening_balance_amount => opening_balance_amount, :opening_balance_currency => opening_balance_currency, :opening_balance_effect => opening_balance_effect, :accounts_chart => chart, :ledger_classification_id => ledger_classification_id)
        AccountingLocation.first_or_create(:product_type => 'ledger', :product_id => ledger.id, :cost_center => cost_center, :effective_on => Date.today, :performed_by => performed_by, :recorded_by => recorded_by)
      }
    }
  end

  def self.setup_product_ledgers(with_accounts_chart, currency, open_on_date, for_product_type = nil, for_product_id = nil)
    all_product_ledgers = {}
    recorded_by = User.first.id
    performed_by = User.first.staff_member.id
    client = Client.get(with_accounts_chart.counterparty_id)
    client_admin = get_client_facade(User.first).get_administration_on_date(client, open_on_date)
    biz_location = client_admin.blank? ? nil : client_admin.administered_at_location
    parent_location = LocationLink.get_parent(biz_location, open_on_date)
    parent_ledgers = parent_location.blank? ? [] : parent_location.accounting_locations.map(&:product).flatten.compact
    PRODUCT_LEDGER_TYPES.each { |product_ledger_type|
      ledger_classification = LedgerClassification.resolve(product_ledger_type)

      ledger_is_product_specific = ledger_classification.is_product_specific?
      if (for_product_type.nil? and for_product_id.nil?)
        next if ledger_is_product_specific
      end

      ledger_product_type, ledger_product_id = ledger_is_product_specific ? [for_product_type, for_product_id] : [nil, nil]

      ledger_assignment = LedgerAssignment.record_ledger_assignment(with_accounts_chart, ledger_classification, ledger_product_type, ledger_product_id)
      ledger_name = name_for_product_ledger(with_accounts_chart.counterparty_type, with_accounts_chart.counterparty_id, ledger_classification, ledger_product_type, ledger_product_id)
      account_type = ledger_classification.account_type
      
      ledger = {}
      ledger[:name] = ledger_name
      ledger[:account_type] = account_type
      ledger[:open_on] = open_on_date
      ledger[:opening_balance_amount] = 0
      ledger[:opening_balance_currency] = currency
      ledger[:opening_balance_effect] = DEFAULT_EFFECTS_BY_TYPE[account_type]
      ledger[:accounts_chart] = with_accounts_chart
      ledger[:ledger_classification] = ledger_classification
      ledger[:ledger_assignment] = ledger_assignment
      product_ledger = first_or_create(ledger)
      
      raise Errors::DataError, product_ledger.errors.first.first if product_ledger.id.nil?
      parent_ledgers = parent_ledgers.uniq unless parent_ledgers.blank?
      parent_ledger = parent_ledgers.select{|l| l.ledger_classification == ledger_classification}.first
      all_product_ledgers[ledger_classification.account_purpose] = product_ledger
      unless product_ledger.id.blank?
        link = LocationLink.first(:model_type => 'Ledger', :child_id => product_ledger.id, :effective_on => product_ledger.open_on)
        LocationLink.assign(product_ledger, parent_ledger, open_on_date) if link.blank? && !parent_ledger.blank?
        AccountingLocation.first_or_create(:product_type => 'ledger', :product_id => product_ledger.id, :biz_location => biz_location, :effective_on => open_on_date, :performed_by => performed_by, :recorded_by => recorded_by)
      end
    }
    all_product_ledgers
  end

  def self.setup_location_ledgers(open_on_date, for_location_id)
    h_cost_center = CostCenter.first(:name => 'Head Office')
    location = BizLocation.get(for_location_id)
    cost_center = location.cost_center
    cost_center_id = cost_center.blank? ? nil : cost_center.id
    recorded_by = User.first.id
    performed_by = User.first.staff_member.id
    parent_ledgers = h_cost_center.accounting_locations(:product_type => 'ledger', :effective_on.gte => open_on_date).map(&:product)
    parent_ledgers = parent_ledgers.compact.uniq unless parent_ledgers.blank?
    DEFAULT_LEDGERS.each do |key, name|
      parent_ledger = parent_ledgers.select{|l| l.name == name}.first
      unless parent_ledger.blank?
        ledger = {}
        ledger_classification = LedgerClassification.resolve(key)
        ledger[:name] = location.name+"(#{location.id})-"+name
        ledger[:account_type] = parent_ledger.account_type
        ledger[:open_on] = open_on_date
        ledger[:opening_balance_amount] = 0
        ledger[:opening_balance_currency] = parent_ledger.opening_balance_currency
        ledger[:opening_balance_effect] = parent_ledger.opening_balance_effect
        ledger[:accounts_chart] = parent_ledger.accounts_chart
        ledger[:ledger_classification] = ledger_classification
        ledger[:manual_voucher_permitted] = true
        ledger_obj = first_or_create(ledger)
        LocationLink.assign(ledger_obj, parent_ledger)
        AccountingLocation.first_or_create(:product_type => 'ledger', :biz_location_id => location.id, :product_id => ledger_obj.id, :cost_center_id => cost_center_id, :effective_on => open_on_date, :performed_by => performed_by, :recorded_by => recorded_by)
      end
    end
  end

  def self.save_ledger(name, account_type, open_on, opening_balance, effect)
    chart = AccountsChart.first
    opening_balance_amount = MoneyManager.get_money_instance(opening_balance.to_i)
    fields = {}
    fields[:name] = name
    fields[:account_type] = account_type.to_sym
    fields[:open_on] = open_on
    fields[:opening_balance_amount] = opening_balance_amount.amount
    fields[:opening_balance_currency] = DEFAULT_CURRENCY
    fields[:opening_balance_effect] = effect
    fields[:accounts_chart] = chart
    fields[:manual_voucher_permitted] = true
    self.new(fields)
  end

  def self.name_for_product_ledger(counterparty_type, counterparty_id, ledger_classification, product_type = nil, product_id = nil)
    name = "#{ledger_classification} #{counterparty_type}: #{counterparty_id}"
    name += " for #{product_type}: #{product_id}" if (product_type and product_id)
    name
  end
  def get_vouchers_on_date(on_date = Date.today)
    ledger_vouchers = []
    ledger_vouchers = self.vouchers.all(:effective_on => on_date)
    if ledger_vouchers.blank?
      child_ledgers = LocationLink.all_children(self, on_date)
      child_ledgers.each{|ledger| ledger_vouchers << ledger.vouchers.all(:effective_on => on_date)}
    end
    ledger_vouchers.flatten.uniq
  end

  def get_vouchers(till_date = Date.today, cost_center_id = nil)
    ledger_vouchers = []
    if cost_center_id.blank?
      ledger_vouchers = self.vouchers.all(:effective_on.lte => till_date)
    else
      biz_location    = CostCenter.get(cost_center_id).biz_location
      biz_location_id = biz_location.blank? ? nil : biz_location.id
      self.ledger_postings.group_by{|posting| posting.voucher}.each do |voucher, postings|
        unless voucher.blank?
          ledger_vouchers << voucher if voucher.effective_on <= till_date && !postings.blank? && postings.map(&:accounted_at).include?(biz_location_id)
        end
      end
    end
    ledger_vouchers.flatten.blank? ? ledger_vouchers.flatten : ledger_vouchers.flatten.compact
  end

  def self.run_branch_eod_accounting(location, on_date = Date.today)
    loans = get_location_facade(User.first).get_loans_accounted(location.id, on_date)
    disbursed_amount = due_principal = due_interest = due_total = collect_principal = collect_interest = collect_total = collect_advance = MoneyManager.default_zero_money
    adjusted_advance = loan_preclosure_principal = loan_preclosure_interest = loan_preclosure_adjusted_advance = loan_write_off_pricipal =loan_write_off_recovery = MoneyManager.default_zero_money
    charges_amount   = FeeReceipt.all(:accounted_at => location.id, :effective_on => on_date).map(&:fee_amount).sum
    charges_amount   = charges_amount.blank? ? 0 : charges_amount
    charges_money_amt = charges_amount > 0 ? Money.new(charges_amount.to_i, MoneyManager.get_default_currency) : MoneyManager.default_zero_money
    loans = loans.compact.uniq unless loans.blank?
    loans.each do |loan|
      if loan.is_disbursed?
        disbursed_amount += loan.to_money[:disbursed_amount] if loan.disbursal_date == on_date
        installment = loan.loan_base_schedule.get_schedule_line_item(on_date)
        unless installment.blank?
          due_principal += installment.to_money[:scheduled_principal_due]
          due_interest += installment.to_money[:scheduled_interest_due]
          due_total += due_principal+due_interest
        end
        collect_principal += loan.principal_received_on_date(on_date)
        collect_interest += loan.interest_received_on_date(on_date)
        collect_advance += loan.advance_received_on_date(on_date)
        adjusted_advance += loan.advance_adjusted_on_date(on_date)
      end
      if loan.is_written_off?
        if loan.write_off_on_date == on_date
          total_loan_disbursed = loan.to_money[:disbursed_amount]
          total_principal_received = loan.principal_received_till_date(on_date)
          write_off_on_amount = total_loan_disbursed - total_principal_received
          loan_write_off_pricipal += write_off_on_amount
        end
        loan_write_off_recovery += loan.loan_recovery_on_date(on_date)
      end
      if loan.is_preclosed?
        loan_preclosure_principal += loan.principal_received_on_date(on_date)
        loan_preclosure_interest += loan.interest_received_on_date(on_date)
        loan_preclosure_adjusted_advance += loan.advance_adjusted_on_date(on_date)
      end
    end
    Constants::Transaction::PRODUCT_ACTIONS+[MONEY_DEPOSIT, WRITE_OFF].each do |action|
      case action
      when LOAN_DISBURSEMENT
        payment_allocation = {:loan_disbursed => disbursed_amount, :total_paid => disbursed_amount}
        total_amount = disbursed_amount
      when LOAN_REPAYMENT
        total_collect = collect_principal + collect_interest + collect_advance
        payment_allocation = {:total_received => total_collect, :interest_received => collect_interest, :principal_received => collect_principal, :advance_received => collect_advance}
        total_amount = total_collect
      when LOAN_ADVANCE_ADJUSTMENT
        payment_allocation = {:advance_adjusted => adjusted_advance}
        total_amount = adjusted_advance
      when LOAN_RECOVERY
        payment_allocation = {:total_received => loan_write_off_recovery}
        total_amount = loan_write_off_recovery
      when WRITE_OFF
        payment_allocation = {:total_received => loan_write_off_pricipal }
        total_amount = loan_write_off_pricipal
      when LOAN_FEE_RECEIPT
        payment_allocation = {:total_received => charges_money_amt}
        total_amount = charges_money_amt
      when LOAN_PRECLOSURE
        total_amount = (loan_preclosure_principal+loan_preclosure_interest) - loan_preclosure_adjusted_advance
        payment_allocation = {:total_received => total_amount, :principal_received => loan_preclosure_principal}
      when MONEY_DEPOSIT
        money_deposits = MoneyDeposit.all(:created_on => on_date, :at_location_id => location.id, :verification_status => Constants::MoneyDepositVerificationStatus::VERIFIED_CONFIRMED)
        total_amount = money_deposits.blank? ? MoneyManager.default_zero_money : money_deposits.map(&:deposit_money_amount).sum
        payment_allocation = {:total_received => total_amount}
      else
        total_amount = MoneyManager.default_zero_money
      end
      if total_amount > MoneyManager.default_zero_money
        product_accounting_rule = ProductAccountingRule.resolve_rule_for_product_action(action)
        postings = product_accounting_rule.get_location_posting_info(payment_allocation, location.id, on_date)
        receipt_type = action == LOAN_DISBURSEMENT ? Constants::Transaction::PAYMENT : Constants::Transaction::RECEIPT
        Voucher.create_generated_voucher(total_amount.amount, receipt_type, total_amount.currency, on_date, postings, location.id, '', "EOD Voucher Entry For #{action} on #{on_date}")
      end
    end
  end
  def self.run_branch_bod_accounting(location, on_date = Date.today)
    loans = get_location_facade(User.first).get_loans_accounted(location.id, on_date)
    loans = loans.compact.uniq unless loans.blank?
    due_principal = due_interest = MoneyManager.default_zero_money
    action = :loan_due
    loans.each do |loan|
      if loan.is_disbursed?
        installment = loan.loan_base_schedule.get_schedule_line_item(on_date)
        unless installment.blank?
          due_principal += installment.to_money[:scheduled_principal_due]
          due_interest += installment.to_money[:scheduled_interest_due]
        end
      end
    end
    total_due = due_principal + due_interest
    if total_due > MoneyManager.default_zero_money
      payment_allocation = {:total_received => total_due, :principal_received => due_principal, :interest_received => due_interest}
      product_accounting_rule = ProductAccountingRule.resolve_rule_for_product_action(action)
      postings = product_accounting_rule.get_location_posting_info(payment_allocation, location.id, on_date)
      receipt_type = action == LOAN_DISBURSEMENT ? Constants::Transaction::PAYMENT : Constants::Transaction::RECEIPT
      Voucher.create_generated_voucher(total_due.amount, receipt_type, total_due.currency, on_date, postings, location.id, '', "Voucher created for Loan Due Generation on #{on_date}")
    end
  end

  def self.head_office_eod(on_date)
    head_office = CostCenter.first(:name => 'Head Office')
    on_date = Date.parse(on_date.to_s) if on_date.class != Date
    h_ledgers = head_office.accounting_locations(:product_type => 'ledger', :effective_on.lte => on_date).map(&:product)
    h_ledgers = h_ledgers.compact.uniq unless h_ledgers.blank?
    ledger_classification = LedgerClassification.resolve(:loan_disbursement)
    all_vouchers = Voucher.all(:eod => false)
    h_ledgers.each do |h_ledger|
      ledger_balances = {}
      postings_collection = []
      c_ledgers = LocationLink.get_children(h_ledger, on_date)
      c_vouchers = []
      c_ledgers.each do |c_ledger|
        t_vouchers = c_ledger.vouchers.all(:eod => false)
        unless t_vouchers.blank?
          c_vouchers += all_vouchers & t_vouchers
          all_vouchers = all_vouchers - t_vouchers
        end
      end
      c_vouchers = c_vouchers.flatten.compact.uniq unless c_vouchers.blank?
      c_vouchers.uniq.group_by{|v| v.effective_on}.each do |effective_date, vouchers|
        vouchers.group_by{|v| v.narration}.each do |narration, vouchers|
          postings_collection = []
          ledger_postings = vouchers.map(&:ledger_postings).flatten
          ledger_postings.group_by{ |lp| lp.ledger }.each do |ledger, postings|
            postings.group_by{|p| p.ledger.ledger_classification}.each do |classification, c_postings|
              ledger_balances[ledger] = LedgerBalance.add_balances(LedgerBalance.zero_debit_balance(:INR), *c_postings)
              parent_ledger = LocationLink.get_parent(ledger, on_date)
              postings_collection << PostingInfo.new(ledger_balances[ledger].amount, ledger_balances[ledger].currency, ledger_balances[ledger].effect, parent_ledger, '', '')
            end
          end
          total_amount = ledger_balances.values.select{|l| l.effect == :credit}.sum||MoneyManager.default_zero_money
          if total_amount > MoneyManager.default_zero_money
            voucher_postings = []
            posting = postings_collection.select{|p| p.ledger.ledger_classification == ledger_classification && p.effect==:credit}
            receipt_type = posting.blank? ? Constants::Transaction::RECEIPT : Constants::Transaction::PAYMENT
            postings_collection.group_by{|g| g.ledger}.each do |ledger, posting_info|
              if posting_info.size > 1
                amt = posting_info.map(&:amount).sum
                parent_ledger = ledger
                currency = posting_info.first.currency
                effect = posting_info.first.effect
                voucher_postings << PostingInfo.new(amt, currency, effect, parent_ledger, '', '')
              else
                voucher_postings << posting_info
              end
            end
            Voucher.create_generated_voucher(total_amount.amount, receipt_type , total_amount.currency, effective_date, voucher_postings.flatten, '', '', narration, true)
            vouchers.each{|d| d.update(:eod=>true)}
          end
        end
      end
    end
  end

  def self.location_accounting_eod(location, on_date)
    on_date = Date.parse(on_date.to_s) if on_date.class != Date
    h_ledgers = location.accounting_locations(:product_type => 'ledger', :effective_on.lte => on_date).map(&:product)
    h_ledgers = h_ledgers.compact.uniq unless h_ledgers.blank?
    ledger_classification = LedgerClassification.resolve(:customer_loan_disbursed)
    h_ledgers.each do |h_ledger|
      ledger_balances = {}
      postings_collection = []
      c_ledgers = LocationLink.get_children_by_sql(h_ledger, on_date)
      c_vouchers = []
      c_ledgers.each do |c_ledger|
        t_vouchers = c_ledger.vouchers(:eod => false)
        unless t_vouchers.blank?
          c_vouchers += t_vouchers
        end
      end
      c_vouchers = c_vouchers.flatten.compact.uniq unless c_vouchers.blank?
      c_vouchers.uniq.group_by{|v| v.effective_on}.each do |effective_date, vouchers|
        vouchers.group_by{|v| v.narration}.each do |narration, vouchers|
          postings_collection = []
          ledger_postings = vouchers.map(&:ledger_postings).flatten
          ledger_postings.group_by{ |lp| lp.ledger }.each do |ledger, postings|
            postings.group_by{|p| p.ledger.ledger_classification}.each do |classification, c_postings|
              ledger_balances[ledger] = LedgerBalance.add_balances(LedgerBalance.zero_debit_balance(:INR), *c_postings)
              parent_ledger = LocationLink.get_parent(ledger, on_date)
              postings_collection << PostingInfo.new(ledger_balances[ledger].amount, ledger_balances[ledger].currency, ledger_balances[ledger].effect, parent_ledger, location.id, '')
            end
          end
          total_amount = ledger_balances.values.select{|l| l.effect == :credit}.sum||MoneyManager.default_zero_money
          if total_amount > MoneyManager.default_zero_money
            voucher_postings = []
            posting = postings_collection.select{|p| !p.ledger.blank? && p.ledger.ledger_classification_id == ledger_classification.id && p.effect==:credit}
            receipt_type = posting.blank? ? Constants::Transaction::RECEIPT : Constants::Transaction::PAYMENT
            postings_collection.group_by{|g| g.ledger}.each do |ledger, posting_info|
              if posting_info.size > 1
                amt = posting_info.map(&:amount).sum
                parent_ledger = ledger
                currency = posting_info.first.currency
                effect = posting_info.first.effect
                voucher_postings << PostingInfo.new(amt, currency, effect, parent_ledger, location.id, '')
              else
                voucher_postings << posting_info
              end
            end
            Voucher.create_generated_voucher(total_amount.amount, receipt_type , total_amount.currency, effective_date, voucher_postings.flatten, '', location.id, "EOD :- "+narration)
            vouchers.each{|d| d.update(:eod=>true)}
          end
        end
      end
    end
  end

#  def self.setup_location_link
#    ClientAdministration.all.each do |client_admin|
#      a_chart = AccountsChart.first(:counterparty_id => client_admin.counterparty_id)
#      ledgers = a_chart.blank? ? [] : a_chart.ledgers
#      parent_location = client_admin.registered_at_location
#      parent_ledger_ids = parent_location.blank? ? [] : parent_location.accounting_locations.map(&:product_id).flatten.compact
#      parent_ledgers = Ledger.all(:id => parent_ledger_ids)
#      unless parent_ledgers.blank?
#        links = LocationLink.all(:model_type => 'Ledger', :child_id => ledgers.map(&:id)).map(&:child_id)
#        assign_ledgers = ledgers.select{|l| !links.include?(l.id) }
#        assign_ledgers.each do |ledger|
#          parent_ledger = parent_ledgers.select{|l| l.ledger_classification_id == ledger.ledger_classification_id}.first
#          unless parent_ledger.blank?
#            LocationLink.assign(ledger, parent_ledger, ledger.open_on)
#            AccountingLocation.first_or_create(:product_type => 'ledger', :product_id => ledger.id, :biz_location_id => client_admin.administered_at, :effective_on => ledger.open_on, :performed_by => 1, :recorded_by => 1)
#          end
#        end
#      end
#    end
#  end

  def self.setup_location_link
    BizLocation.all('location_level.level' => 1).each do |parent_location|
      clients = ClientAdministration.get_clients_registered_by_sql(parent_location.id, Date.today)
      ledgers = Ledger.all('accounts_chart.counterparty_id' => clients.map(&:id))
      parent_ledger_ids = parent_location.accounting_locations.map(&:product_id).flatten.compact
      parent_ledgers = Ledger.all(:id => parent_ledger_ids)
      unless parent_ledgers.blank?
        links = LocationLink.all(:model_type => 'Ledger', :child_id => ledgers.map(&:id)).map(&:child_id)
        assign_ledgers = ledgers.select{|l| !links.include?(l.id) }
        assign_ledgers.each do |ledger|
          parent_ledger = parent_ledgers.select{|l| l.ledger_classification_id == ledger.ledger_classification_id}.first
          unless parent_ledger.blank?
            LocationLink.assign(ledger, parent_ledger, ledger.open_on)
            client_admin = ClientAdministration.last(:counterparty_id => ledger.accounts_chart.counterparty_id)
            AccountingLocation.first_or_create(:product_type => 'ledger', :product_id => ledger.id, :biz_location_id => client_admin.administered_at, :effective_on => ledger.open_on, :performed_by => 1, :recorded_by => 1) unless client_admin.blank?
          end
        end
      end
    end
  end

  def self.update_ledger_names
    head_office = CostCenter.first(:name => 'Head Office')
    h_ledgers = head_office.accounting_locations(:product_type => 'ledger').map(&:product)
    ledger_names = {'Cash' =>"Cash",'Bank Account'=>'Bank Account','Loans Made' => 'Micro Finance Loan','Debtors'=>'Debtors-Mf Loan','Loans Write Off'=>'Bad Debts','Loans Advance'=>'Advance for Ewi','Interest Income'=>'Interest on Microfinance Loan','Charges Income' =>'Service Charges','Other Income'=>'Bad Debts Recover'}
    ledger_names.each do |ledger, new_ledger|
      h_ledger = h_ledgers.select{|l| l.name == ledger}.first
      if !h_ledger.blank?
        h_ledger.update(:name => new_ledger) if h_ledger.name != new_ledger
        c_ledgers = LocationLink.get_children_by_sql(h_ledger, Date.today)
        c_ledgers.each do |c_ledger|
          c_name = c_ledger.name
          c_new_name = c_name.sub(ledger, new_ledger)
          c_ledger.update(:name => c_new_name) if c_new_name != c_name
        end
      end
    end
  end

  def self.get_location_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user)
  end

  def self.get_client_facade(user)
    @client_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::CLIENT_FACADE, user)
  end

end