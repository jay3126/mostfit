class AccrualTransaction
  include DataMapper::Resource
  include Constants::Properties, Constants::Money, Constants::Transaction, Constants::Accounting

  property :id, Serial
  property :accrual_allocation_type, Enum.send('[]', *ACCRUAL_ALLOCATION_TYPES), :nullable => false
  property :amount,                  *MONEY_AMOUNT
  property :currency,                *CURRENCY
  property :accrual_temporal_type,   Enum.send('[]', *ACCRUAL_TEMPORAL_TYPES), :nullable => false
  property :receipt_type,            Enum.send('[]', *RECEIVED_OR_PAID), :nullable => false
  property :on_product_type,         Enum.send('[]', *TRANSACTED_PRODUCTS), :nullable => false
  property :on_product_id,           Integer, :nullable => false
  property :by_counterparty_type,    Enum.send('[]', *COUNTERPARTIES), :nullable => false
  property :by_counterparty_id,      *INTEGER_NOT_NULL
  property :performed_at,            *INTEGER_NOT_NULL
  property :accounted_at,            *INTEGER_NOT_NULL
  property :effective_on,            *DATE_NOT_NULL
  property :accounting,               Boolean, :default => false
  property :created_at,              *CREATED_AT

  def money_amounts; [ :amount ]; end
  def accrual_money_amount; to_money_amount(:amount); end
  def accounted_location; BizLocation.get(self.accounted_at); end
  def counterparty; Resolver.fetch_counterparty(self.by_counterparty_type, self.by_counterparty_id); end

  def product_action
    PRODUCT_ACTIONS_FOR_ACCRUAL_TRANSACTIONS[self.on_product_type][self.accrual_temporal_type][self.accrual_allocation_type]
  end
  
  def self.record_accrual(accrual_allocation_type, money_amount, receipt_type, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, effective_on, accrual_temporal_type, accounting = false)
    Validators::Arguments.not_nil?(accrual_allocation_type, money_amount, receipt_type, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, effective_on, accrual_temporal_type, accounting)
    accrual = to_accrual(accrual_allocation_type, money_amount, receipt_type, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, effective_on, accrual_temporal_type, accounting)
    recorded_accrual = first_or_create(accrual)
    raise Errors::DataError, recorded_accrual.errors.first.first unless recorded_accrual.saved?
    recorded_accrual
  end

  def self.to_accrual(accrual_allocation_type, money_amount, receipt_type, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, effective_on, accrual_temporal_type, accounting = false)
    accrual = {}
    accrual[:accrual_allocation_type] = accrual_allocation_type
    accrual[:amount] = money_amount.amount
    accrual[:currency] = money_amount.currency
    accrual[:receipt_type] = receipt_type
    accrual[:on_product_id] = on_product_id
    accrual[:on_product_type] = on_product_type
    accrual[:by_counterparty_type] = by_counterparty_type
    accrual[:by_counterparty_id] = by_counterparty_id
    accrual[:performed_at] = performed_at
    accrual[:accounted_at] = accounted_at
    accrual[:effective_on] = effective_on
    accrual[:accrual_temporal_type] = accrual_temporal_type
    accrual[:accounting] = accounting
    accrual
  end

  def to_reversed_broken_period_accrual
    return nil unless self.accrual_temporal_type == ACCRUE_BROKEN_PERIOD
    original_accrual_attributes = self.attributes.dup
    original_accrual_attributes.delete(:id)
    original_accrual_attributes.delete(:created_at)
    reversal_attributes = original_accrual_attributes

    reversal_attributes[:accrual_temporal_type] = REVERSE_BROKEN_PERIOD_ACCRUAL
    reversal_attributes[:effective_on] = (self.effective_on + 1)
    AccrualTransaction.first_or_new(reversal_attributes)
  end

  def is_reversed?
    return true unless self.accrual_temporal_type == ACCRUE_BROKEN_PERIOD
    ReversedAccrualLog.reversal_for_accrual(self.id)
  end

  def self.all_broken_period_interest_accruals_not_reversed(on_date)
    broken_period_accruals_on_date = {}
    broken_period_accruals_on_date[:effective_on] = on_date
    broken_period_accruals_on_date[:accrual_temporal_type] = ACCRUE_BROKEN_PERIOD
    all_broken_period_accruals_on_date = all(broken_period_accruals_on_date)
    all_broken_period_accruals_on_date.reject {|bpial| bpial.is_reversed?}
  end

  def self.reversed_accruals_for_not_recevied(loan_id, on_date = Date.today)
    loan = Lending.get(loan_id)
    loan_receipts = LoanReceipt.all(:lending_id => loan_id)
    principal_accrued_transaction  = AccrualTransaction.all(:accrual_allocation_type => ACCRUE_PRINCIPAL_ALLOCATION, :accrual_temporal_type => ACCRUE_REGULAR, :on_product_id => loan_id, :on_product_type => 'lending', :effective_on.lte => on_date)
    interest_accrued_transaction  = AccrualTransaction.all(:accrual_allocation_type => ACCRUE_INTEREST_ALLOCATION, :accrual_temporal_type => ACCRUE_REGULAR, :on_product_id => loan_id, :on_product_type => 'lending', :effective_on.lte => on_date)
    principal_received = loan_receipts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts.map(&:principal_received).sum.to_i)
    interest_received =  loan_receipts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts.map(&:interest_received).sum.to_i)

    principal_accrued = principal_accrued_transaction.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(principal_accrued_transaction.map(&:amount).sum.to_i)
    interest_accrued = interest_accrued_transaction.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(interest_accrued_transaction.map(&:amount).sum.to_i)
    if principal_received < principal_accrued
      principal_accrual_obj = principal_accrued_transaction.first
      original_accrual_attributes = principal_accrual_obj.attributes.dup
      original_accrual_attributes.delete(:id)
      original_accrual_attributes.delete(:created_at)
      principal_reversal_attributes = original_accrual_attributes
      principal_reversal_attributes[:amount] = (principal_accrued - principal_received).amount
      principal_reversal_attributes[:accrual_temporal_type] = REVERSE_ACCRUE_REGULAR
      principal_reversal_attributes[:accrual_allocation_type] = REVERSE_ACCRUE_PRINCIPAL_ALLOCATION
      principal_reversal_attributes[:effective_on] = on_date
      AccrualTransaction.first_or_create(principal_reversal_attributes)
    end
    if interest_received < interest_accrued
      interest_accrual_obj = interest_accrued_transaction.first
      original_accrual_attributes = interest_accrual_obj.attributes.dup
      original_accrual_attributes.delete(:id)
      original_accrual_attributes.delete(:created_at)
      interest_reversal_attributes = original_accrual_attributes
      interest_reversal_attributes[:amount] = (interest_accrued - interest_received).amount
      interest_reversal_attributes[:accrual_temporal_type] = REVERSE_ACCRUE_REGULAR
      interest_reversal_attributes[:accrual_allocation_type] = REVERSE_ACCRUE_INTEREST_ALLOCATION
      interest_reversal_attributes[:effective_on] = on_date
      AccrualTransaction.first_or_create(interest_reversal_attributes)
    end
  end

  def self.record_in_csv_file(location_id = nil)

    locations = location_id.blank? ? BizLocation.all('location_level.level' => 1) : [BizLocation.get(location_id)]
    folder = File.join(Merb.root, "doc", "xls", "company",'reports', 'generate_accrual')
    FileUtils.mkdir_p(folder)
    csv_loan_file = File.join(folder, "jan_accrual.csv")
    File.new(csv_loan_file, "w").close
    header = [["Branch Name","Loan lan" ,"Jan Principal Due Date", 'Jan Principal Due',"Jan Interest Due Date", "Jan Interest Due", "Jan Broken Reverse Interest", "Jan Broken Peroid Interest", "Reverse Principal Date", "Reverse Principal Due", "Reverse Interset Date", "Reverse Interest Due"]]
    append_to_file_as_csv(header, csv_loan_file)
    locations.each do |location|

      loans = LoanAdministration.get_loan_ids_accounted_by_sql(location.id, Date.today, false, '')
      accruals = all(:on_product_id => loans).group_by{|s| s.on_product_id}
      accruals.each do |loan_id, l_accruals|
        lan = Lending.first(:fields =>[ :lan], :id => loan_id).lan
        jan_accruals = []
        jan_accruals = l_accruals.select{|s| s.effective_on >= Date.new(2013,1,1) and s.effective_on <= Date.new(2013,1,31)}
        unless jan_accruals.blank?
          j_value = [location.name, lan]
          j_broken_interest_reverse = jan_accruals.select{|s| s.accrual_temporal_type == REVERSE_BROKEN_PERIOD_ACCRUAL}
          j_principal_accrued = jan_accruals.select{|s| s.accrual_allocation_type == ACCRUE_PRINCIPAL_ALLOCATION and s.accrual_temporal_type == ACCRUE_REGULAR}
          j_interest_accrued = jan_accruals.select{|s| s.accrual_allocation_type == ACCRUE_INTEREST_ALLOCATION and s.accrual_temporal_type == ACCRUE_REGULAR}
          j_broken_accrued = jan_accruals.select{|s| s.accrual_temporal_type == ACCRUE_BROKEN_PERIOD}
          j_principal_reversed = jan_accruals.select{|s| s.accrual_allocation_type == REVERSE_ACCRUE_PRINCIPAL_ALLOCATION}
          j_interest_reversed = jan_accruals.select{|s| s.accrual_allocation_type == REVERSE_ACCRUE_INTEREST_ALLOCATION}
          j_value <<  "#{j_principal_accrued.blank? ? '-' : j_principal_accrued.first.effective_on}"
          j_value <<  "#{j_principal_accrued.blank? ? '-' : (j_principal_accrued.map(&:amount).sum/100).to_f}"
          j_value <<  "#{j_interest_accrued.blank? ? '-' : j_interest_accrued.first.effective_on}"
          j_value <<  "#{j_interest_accrued.blank? ? '-' : (j_interest_accrued.map(&:amount).sum/100).to_f}"
          j_value <<  "#{j_broken_interest_reverse.blank? ? '-' : (j_broken_interest_reverse.map(&:amount).sum/100).to_f}"
          j_value <<  "#{j_broken_accrued.blank? ? '-' : (j_broken_accrued.map(&:amount).sum/100).to_f}"
          j_value <<  "#{j_principal_reversed.blank? ? '-' : j_principal_reversed.first.effective_on}"
          j_value <<  "#{j_principal_reversed.blank? ? '-' : (j_principal_reversed.map(&:amount).sum/100).to_f}"
          j_value <<  "#{j_interest_reversed.blank? ? '-' : j_interest_reversed.first.effective_on}"
          j_value <<  "#{j_interest_reversed.blank? ? '-' : (j_interest_reversed.map(&:amount).sum/100).to_f}"
        end
        append_to_file_as_csv([j_value], csv_loan_file) unless j_value.blank?
      end
    end
  end

  def self.append_to_file_as_csv(data, filename)
    FasterCSV.open(filename, "a", {:col_sep => ","}) do |csv|
      data.each do |datum|
        csv << datum
      end
    end
  end

end
