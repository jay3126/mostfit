class Voucher
  include DataMapper::Resource
  include PostingValidator
  include Constants::Properties

  property :id,             Serial
  property :guid,           *UNIQUE_ID
  property :total_amount,   *MONEY_AMOUNT_NON_ZERO
  property :currency,       *CURRENCY
  property :effective_on,   *DATE_NOT_NULL
  property :narration,      String, :length => 1024
  property :generated_mode, Enum.send('[]', *VOUCHER_MODES), :nullable => false
  property :created_at,     *CREATED_AT

  has n, :ledger_postings

  def money_amounts; [ :total_amount ]; end

  validates_present :effective_on
  validates_with_method :validate_has_both_debits_and_credits?, :postings_are_each_valid?, :postings_are_valid_together?, :postings_add_up?, :validate_all_post_to_unique_accounts?
  validates_with_method :manual_voucher_permitted?
  
  def manual_voucher_permitted?
    return true unless self.generated_mode == MANUAL_VOUCHER
    self.ledger_postings.any? {|posting| (not (posting.ledger.manual_voucher_permitted?))} ? [false, "One or more ledgers do not permit manual vouchers"] :
      true
  end

  def voucher_type; "RECEIPT"; end

  def self.create_generated_voucher(total_amount, currency, effective_on, postings, notation = nil)
    create_voucher(total_amount, currency, effective_on, notation, postings, GENERATED_VOUCHER)
  end

  def self.create_manual_voucher(total_money_amount, effective_on, postings, notation = nil)
    create_voucher(total_money_amount.amount, total_money_amount.currency, effective_on, notation, postings, MANUAL_VOUCHER)
  end

  def self.get_postings(ledger, to_date = Date.today, from_date = nil)
    LedgerPosting.all_postings_on_ledger(ledger, to_date, from_date)
  end

  def self.find_by_date_and_cost_center(on_date)
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
              debit_postings, credit_postings = voucher.ledger_postings.group_by{ |ledger_posting| ledger_posting.effect }.values
              x.VOUCHER{
                x.DATE voucher.effective_on.strftime("%Y%m%d")
                x.NARRATION voucher.narration
                x.VOUCHERTYPENAME voucher.voucher_type
                x.VOUCHERNUMBER voucher.id
                x.REMOTEID voucher.guid
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
                    x.AMOUNT(debit_posting.to_balance.to_regular_amount)
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

  private

  def self.create_voucher(total_amount, currency, effective_on, notation, postings, generated_mode)
    values = {}
    values[:total_amount] = total_amount
    values[:currency] = currency
    values[:effective_on] = effective_on
    values[:narration] = notation if notation
    values[:generated_mode] = generated_mode
    ledger_postings = []
    postings.each { |p|
      next unless p.amount > 0
      posting = {}
      posting[:effective_on] = effective_on
      posting[:amount] = p.amount
      posting[:currency] = p.currency
      posting[:effect] = p.effect
      posting[:ledger] = p.ledger
      ledger_postings.push(posting)
    }
    values[:ledger_postings] = ledger_postings
    create(values)
  end  

end
