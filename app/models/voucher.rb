class Voucher
  include DataMapper::Resource
  include PostingValidator
  include Constants::Properties

  property :id,             Serial
  property :guid,           *UNIQUE_ID
  property :type,           Enum.send('[]', *VOUCHER_TYPE), :nullable => false
  property :total_amount,   *MONEY_AMOUNT_NON_ZERO
  property :currency,       *CURRENCY
  property :effective_on,   *DATE_NOT_NULL
  property :narration,      String, :length => 1024
  property :generated_mode, Enum.send('[]', *VOUCHER_MODES), :nullable => false
  property :mode_of_accounting, Enum.send('[]', *ACCOUNTING_MODES), :nullable => false, :default => PRODUCT_ACCOUNTING
  property :accounted_at,   Integer
  property :performed_at,   Integer
  property :eod,            Boolean, :default => false
  property :created_at,     *CREATED_AT

  has n, :ledger_postings
  belongs_to :cost_center, :nullable => true

  def money_amounts; [ :total_amount ]; end

  validates_present :effective_on
  validates_with_method :validate_has_both_debits_and_credits?, :postings_are_each_valid?, :postings_are_valid_together?, :postings_add_up?#OOO, :validate_all_post_to_unique_accounts?
  validates_with_method :manual_voucher_permitted?

  def performed_at_location; BizLocation.get(self.performed_at); end
  def accounted_at_location; BizLocation.get(self.accounted_at); end

  def cost_center?(cost_center_id)
    if cost_center_id.blank?
      return false
    else
      cost_center =CostCenter.get(cost_center_id)
      self.ledger_postings.map(&:accounted_at).include?(cost_center.biz_location_id)
    end
  end

  def manual_voucher_permitted?
    return true unless self.generated_mode == MANUAL_VOUCHER
    self.ledger_postings.any? {|posting| (not (posting.ledger.manual_voucher_permitted?))} ? [false, "One or more ledgers do not permit manual vouchers"] :
      true
  end

  def voucher_type; "RECEIPT"; end

  def self.create_generated_voucher(total_amount, voucher_type, currency, effective_on, postings, performed_at =nil, accounted_at=nil, notation = nil, eod = false)
    create_voucher(total_amount, voucher_type, currency, effective_on, postings, notation, performed_at, accounted_at, GENERATED_VOUCHER, eod)
  end

  def self.create_manual_voucher(total_money_amount, voucher_type, effective_on, postings, performed_at = nil, accounted_at= nil, notation = nil)
    create_voucher(total_money_amount.amount, voucher_type, total_money_amount.currency, effective_on, postings, notation, performed_at, accounted_at, MANUAL_VOUCHER)
  end

  def self.get_postings(ledger, to_date = Date.today, from_date = nil)
    LedgerPosting.all_postings_on_ledger(ledger, to_date, from_date)
  end

  def self.find_by_date_and_cost_center(on_date, cost_center_id = nil)
    predicates = {}
    predicates[:effective_on] = on_date
    all(predicates)
  end

  def validate_has_both_debits_and_credits?
    has_both_debits_and_credits?(ledger_postings)
  end

  def postings_are_each_valid?
    result, message = true, ""
    ledger_postings.each { |posting|
      result, message = LedgerBalance.valid_balance_obj?(posting)
      break unless result
    }
    result ? true : [result, message]
  end

  def postings_are_valid_together?
    LedgerBalance.can_add_balances?(*ledger_postings)
  end

  def postings_add_up?
    LedgerBalance.are_balanced?(*ledger_postings) ? true : [false, "postings do not balance"]
  end

  def validate_all_post_to_unique_accounts?
    all_post_to_unique_accounts?(ledger_postings)
  end

  def self.sort_chronologically(vouchers)
    vouchers.sort {|v1, v2| (v1.effective_on - v2.effective_on == 0) ? (v1.created_at - v2.created_at) : (v1.effective_on - v2.effective_on)}
  end

  def self.get_voucher_list(search_options = {})
    all(search_options)
  end

  def self.get_voucher_for_cost_center(from_date, to_date, cost_centers)
    vouchers = []
    ledger_ids = []
    cost_centers.each do |cost_center_id|
      cost_center = CostCenter.get cost_center_id
      unless cost_center.biz_location_id.blank?
        biz_location = cost_center.biz_location
        ledger_ids = biz_location.accounting_locations(:product_type => 'ledger').map(&:product_id)
      end
      ledger_ids += cost_center.accounting_locations(:product_type => 'ledger').map(&:product_id)
      l_vouchers = Ledger.all(:id => ledger_ids).vouchers(:effective_on.gte => from_date, :effective_on.lte => to_date) unless ledger_ids.blank?
      vouchers << l_vouchers unless l_vouchers.blank?
    end
    vouchers.blank? ? [] : vouchers.flatten.uniq
  end

  def self.to_tally_xml(voucher_list, xml_file = nil)
    xml_file ||= '/tmp/voucher.xml'
    f = File.open(xml_file,"w")
    x = Builder::XmlMarkup.new(:target => f,:indent => 1)
    x.ENVELOPE{
      x.HEADER {
        x.VERSION "1"
        x.TALLYREQUEST "Import"
        x.TYPE "Data"
        x.ID "Vouchers"
      }

      x.BODY {
        x.DESC{
        }
        x.DATA{
          x.TALLYMESSAGE{
            voucher_list.each do |voucher|
              center_name = voucher.accounted_at_location.name rescue ''
              debit_postings, credit_postings = voucher.ledger_postings.group_by{ |ledger_posting| ledger_posting.effect }.values
              x.VOUCHER{
                x.DATE voucher.effective_on.strftime("%Y%m%d")
                x.NARRATION voucher.narration
                x.VOUCHERTYPENAME voucher.type.blank? ? 'MF'+voucher.voucher_type : 'MF'+voucher.type.to_s.upcase
                x.VOUCHERNUMBER voucher.id
                x.REMOTEID voucher.guid
                x.tag! 'ACCOUNTINGALLOCATIONS.LIST' do
                  x.tag! 'CATEGORYALLOCATIONS.LIST' do
                    x.tag! 'COSTCENTREALLOCATIONS.LIST' do
                      x.NAME(center_name)
                    end
                  end
                end
                credit_postings.each do |credit_posting|
                  x.tag! 'ALLLEDGERENTRIES.LIST' do
                    x.LEDGERNAME(credit_posting.ledger.name)
                    x.ISDEEMEDPOSITIVE("No")
                    x.AMOUNT(credit_posting.to_balance.to_regular_amount)
                  end
                end
                debit_postings.each do |debit_posting|
                  x.tag! 'ALLLEDGERENTRIES.LIST' do
                    x.LEDGERNAME(debit_posting.ledger.name)
                    x.ISDEEMEDPOSITIVE("Yes")
                    x.AMOUNT('-'+debit_posting.to_balance.to_regular_amount)
                  end
                end
              }
            end
          }
        }
      }
    }
    f.close
  end

  def ledger_classifications
    (self.ledger_postings.collect {|ledger_posting| ledger_posting.ledger_classification}).compact.sort
  end

  def is_similar?(other_voucher)
    (self.mode_of_accounting == other_voucher.mode_of_accounting) and
      (self.ledger_classifications == other_voucher.ledger_classifications)
  end

  def self.aggregate_similar_product_vouchers_on_value_date(on_date)
    all_product_vouchers = all_product_vouchers_on_value_date(on_date)
    grouped_by_ledger_classification = all_product_vouchers.group_by {|voucher| voucher.ledger_classifications}
    grouped_by_ledger_classification.values
  end

  def self.all_product_vouchers_on_value_date(on_date)
    all(:mode_of_accounting => PRODUCT_ACCOUNTING, :effective_on => on_date)
  end

  private

  def self.create_voucher(total_amount, voucher_type, currency, effective_on, postings, notation, performed_at, accounted_at, generated_mode, eod = false)

    values = {}
    values[:total_amount] = total_amount
    values[:currency] = currency
    values[:effective_on] = effective_on
    values[:type] = voucher_type
    values[:narration] = notation if notation
    values[:generated_mode] = generated_mode
    values[:eod] = eod
    values[:performed_at] = performed_at unless performed_at.blank?
    values[:accounted_at] = accounted_at unless accounted_at.blank?
    ledger_postings = []
    postings.each { |p|
      next unless p.amount > 0
      posting = {}
      posting[:effective_on] = effective_on
      posting[:amount] = p.amount
      posting[:currency] = p.currency
      posting[:effect] = p.effect
      posting[:ledger] = p.ledger
      posting[:performed_at] = p.performed_at unless p.performed_at.blank?
      posting[:accounted_at] = p.accounted_at unless p.accounted_at.blank?
      ledger_postings.push(posting)
    } 
    values[:ledger_postings] = ledger_postings
    voucher = create(values)
    raise Errors::DataError, voucher.errors.first.first unless voucher.saved?
    voucher
  end

end
