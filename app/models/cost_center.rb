class CostCenter
  include DataMapper::Resource
  include Constants::Accounting

  property :id,         Serial
  property :name,       String, :nullable => false, :unique => true,
    :default => lambda {|obj, p| obj.biz_location.name if (obj.biz_location and obj.biz_location.name)}
  property :created_at, DateTime, :nullable => false, :default => DateTime.now

  belongs_to :biz_location, 'BizLocation', :nullable => true
  has n, :vouchers

  validates_present :name

  def self.resolve_cost_center_by_branch(branch_id)
  	first_or_create(:biz_location_id => branch_id)
  end

  def self.setup_cost_centers(nominal_branches = [])
    first_or_create(:name => DEFAULT_HEAD_OFFICE_COST_CENTER_NAME)
    nominal_branches.each { |branch_id|
      resolve_cost_center_by_branch(branch_id)
    }
  end

  def to_s
    "Cost center: #{name}"
  end

  def <=>(other)
    (other and other.respond_to?(:name)) ? self.name <=> other.name : nil
  end

  def get_sum_of_balances_cost_center(till_date = Date.today, product_name = nil)
    account_type_balance = {}
    all_ledgers          = []
    course_list          = []

    biz_location = self.biz_location
    if biz_location.blank?
      all_ledgers = Ledger.all
      all_ledgers = all_ledgers.select{|l| !l.ledger_postings.blank?}
    else
      child_locations = LocationLink.all_children(biz_location) << biz_location
      centers = child_locations.select{|l| l.location_level.level == 1}.uniq

      ledger_postings = LedgerPosting.all(:accounted_at => centers.map(&:id))
      unless product_name.blank?
        centers.each do |center|
          course_list << LoanAdministration.get_loans_accounted(center.id, Date.today).compact
        end
        course_products = course_list.flatten.uniq.select{|c| c.lending_product.product_type == product_name.to_sym}
        batches         = course_products.blank? ? [] : course_products.uniq.map(&:administered_at_origin)
        ledger_postings = ledger_postings.select{|lp| batches.include?(lp.performed_at)}
      end
      all_ledgers = ledger_postings.blank? ? [] : ledger_postings.map(&:ledger).uniq
    end
    all_ledgers = all_ledgers.select{|s| s.created_at <= till_date}
    unless all_ledgers.blank?
      currency_in_use = all_ledgers.first.balance(Date.today).currency
      zero_balance    = LedgerBalance.zero_debit_balance(currency_in_use)
      all_ledgers.group_by{|l| [l.account_type]}.each do |account_type, ledgers|
        account_type_balance[account_type.first] = ledgers.inject(zero_balance) { |sum, ledger| sum + ledger.balance(Date.today) }
      end
    end
    return all_ledgers, account_type_balance
  end

end