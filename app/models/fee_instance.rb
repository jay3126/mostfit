class FeeReceiptInfo

  attr_reader :fee_instance, :fee_money_amount, :performed_by_id, :effective_on

  def initialize(fee_instance, fee_money_amount, performed_by_id, effective_on)
    Validators::Arguments.not_nil?(fee_instance, fee_money_amount, performed_by_id, effective_on)
    @fee_instance     = fee_instance
    @fee_money_amount = fee_money_amount
    @performed_by_id  = performed_by_id
    @effective_on     = effective_on
  end

end

class FeeInstance
  include DataMapper::Resource
  include Constants::Properties
  include Constants::Fee
  include Constants::Transaction

  property :id,                     Serial
  property :amount,                  *MONEY_AMOUNT
  property :fee_applied_on_type,    Enum.send('[]', *FEE_APPLIED_ON_TYPES), :nullable => false
  property :fee_applied_on_type_id, *INTEGER_NOT_NULL
  property :by_counterparty_type,   Enum.send('[]', *COUNTERPARTIES), :nullable => false
  property :by_counterparty_id,     *INTEGER_NOT_NULL
  property :administered_at,        *INTEGER_NOT_NULL
  property :accounted_at,           *INTEGER_NOT_NULL
  property :applied_on,             *DATE_NOT_NULL
  property :created_at,             *CREATED_AT

  belongs_to :simple_fee_product
  has 1, :fee_receipt

  def money_amount
    MoneyManager.get_money_instance_least_terms(self.amount.to_i)
  end

  def loan_on_fee_instance; Lending.get fee_applied_on_type_id; end
  def policy_on_fee_instance; SimpleInsurancePolicy.get fee_applied_on_type_id; end

  def status(on_date = Date.today)
    amt = self.money_amount.to_s
    is_collected? ? "#{self.simple_fee_product.name.humanize} (#{amt}) Paid on #{self.fee_receipt.effective_on}" : "#{self.simple_fee_product.name.humanize} (#{amt}) Unpaid"
  end

  def administered_at_location; BizLocation.get(self.administered_at); end
  def accounted_at_location; BizLocation.get(self.accounted_at); end

  def effective_total_amount(on_date = Date.today)
    self.money_amount
  end

  def self.register_fee_instance(fee_product, fee_on_type, administered_at_id, accounted_at_id, applied_on)
    raise Errors::DataError, 'Fee Product amount does not exists' if fee_product.effective_timed_amount.blank?
    Validators::Arguments.not_nil?(fee_product, fee_on_type, administered_at_id, accounted_at_id, applied_on)
    fee_instance = {}
    fee_applied_on_type, fee_applied_on_type_id = Resolver.resolve_fee_applied_on(fee_on_type)

    for_counterparty = fee_on_type.counterparty
    by_counterparty_type, by_counterparty_id = Resolver.resolve_counterparty(for_counterparty)
    raise Errors::InvalidConfigurationError, "No counterparty was available for the fee instance" unless for_counterparty

    fee_instance[:by_counterparty_id]     = by_counterparty_id
    fee_instance[:by_counterparty_type]   = by_counterparty_type
    fee_instance[:fee_applied_on_type]    = fee_applied_on_type
    fee_instance[:fee_applied_on_type_id] = fee_applied_on_type_id
    fee_instance[:administered_at]        = administered_at_id
    fee_instance[:accounted_at]           = accounted_at_id
    fee_instance[:applied_on]             = applied_on
    fee_instance[:simple_fee_product]     = fee_product
    fee_instance[:amount]                 = get_fee_amount(fee_on_type, fee_product)
    fee = create(fee_instance)
    raise Errors::DataError, fee.errors.first.first unless fee.saved?
    fee
  end

  def self.all_unpaid_fees(search_options = {})
    (all(search_options)).reject {|fee_instance| fee_instance.is_collected?}
  end

  def self.all_unpaid_loan_fee_instance(lending_id)
    all_unpaid_fees(:fee_applied_on_type => FEE_ON_LOAN, :fee_applied_on_type_id => lending_id).select{|fee_instance| fee_instance.simple_fee_product.fee_charged_on_type == FEE_CHARGED_ON_LOAN}
  end

  def self.unpaid_loan_preclosure_fee_instance(lending_id)
    all_unpaid_fees(:fee_applied_on_type => FEE_ON_LOAN, :fee_applied_on_type_id => lending_id).select{|fee_instance| fee_instance.simple_fee_product.fee_charged_on_type == PRECLOSURE_PENALTY_ON_LOAN}
  end

  def self.all_unpaid_loan_insurance_fee_instance(insurance_ids)
    all_unpaid_fees(:fee_applied_on_type => FEE_ON_INSURANCE, :fee_applied_on_type_id => insurance_ids).select{|fee_instance| fee_instance.simple_fee_product.fee_charged_on_type == PREMIUM_COLLECTED_ON_INSURANCE}
  end

  def is_collected?
    not (self.fee_receipt.nil?)
  end

  def self.get_all_fees_for_instance(fee_on_type)
    fee_applied_on_type, fee_applied_on_type_id = Resolver.resolve_fee_applied_on(fee_on_type)
    all(:fee_applied_on_type => fee_applied_on_type, :fee_applied_on_type_id => fee_applied_on_type_id)
  end

  def self.get_unpaid_fees_for_instance(fee_on_type)
    (get_all_fees_for_instance(fee_on_type)).reject {|fee_instance| fee_instance.is_collected?}
  end

  def self.get_fee_amount(fee_on_type, fee_product)
    fee_applied_on_type, fee_applied_on_type_id = Resolver.resolve_fee_applied_on(fee_on_type)
    fee_timed_amount = fee_product.effective_timed_amount(Date.today)
    if fee_timed_amount.amount_type == PERCENTAGE_AMOUNT
      if fee_applied_on_type == FEE_ON_LOAN
        loan_amount      = fee_on_type.to_money[:disbursed_amount]||fee_on_type.to_money[:applied_amount]
        percentage       = fee_timed_amount.percentage.to_f
        fee_amount       = (percentage/100) * loan_amount.amount
        fee_money_amount = MoneyManager.get_money_instance_least_terms(fee_amount.to_i)
      elsif fee_applied_on_type == FEE_ON_INSURANCE
        fee_money_amount = fee_on_type.to_money[:insured_amount]
      else
        loan_amount = MoneyManager.default_zero_money
      end
    elsif fee_timed_amount.amount_type == FIX_AMOUNT
      fee_money_amount = fee_timed_amount.total_money_amount
    end
    fee_money_amount.blank? ? 0 : fee_money_amount.amount
  end
end