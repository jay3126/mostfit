class SimpleInsurancePolicy
  include DataMapper::Resource
  include Constants::Properties
  include Constants::Insurance, Constants::Money

  property :id,            Serial
  property :insured_name,  String, :nullable => true
  property :insured_type,  Enum.send('[]', *INSURANCE_TYPES), :default => INSURANCE_TYPE_NOT_KNOWN
  property :insurance_for, Enum.send('[]', *INSURED_PERSON_RELATIONSHIPS), :default => INSURED_RELATIONSHIP_NOT_KNOWN
  property :proposed_on,   *DATE_NOT_NULL
  property :insured_on,    *DATE
  property :insured_amount,*MONEY_AMOUNT
  property :currency,      *CURRENCY
  property :expires_on,    *DATE
  property :issued_status, Enum.send('[]', *INSURANCE_ISSUED_STATUSES), :default => INSURANCE_PROPOSED
  property :created_at,    *CREATED_AT

  belongs_to :simple_insurance_product
  belongs_to :client
  belongs_to :lending, :nullable => true
  has n, :insurance_claims

  def money_amounts; [ :insured_amount ]; end
  
  def created_on; self.proposed_on; end

  validates_with_method :policy_proposed_after_client_joined?

  def policy_proposed_after_client_joined?
    return true if (self.client and self.created_on and (self.created_on >= self.client.created_on))
    [false, "The policy created date: #{self.created_on} is before the date the client joined"]
  end

  def self.setup_proposed_insurance(proposed_on_date, from_insurance_product, on_client, on_loan = nil)
    Validators::Arguments.not_nil?(proposed_on_date, from_insurance_product, on_client)
    proposed_insurance = {}
    proposed_insurance[:insured_type]  = from_insurance_product.insured_type
    proposed_insurance[:insurance_for] = from_insurance_product.insurance_for
    proposed_insurance[:proposed_on]   = proposed_on_date

    total_premium_money_amount = from_insurance_product.total_premium_money_amount(proposed_on_date)
    raise Errors::InvalidConfigurationError, "No premium amount was available for #{from_insurance_product} on #{proposed_on_date}" unless total_premium_money_amount
    insured_amount, currency = total_premium_money_amount.amount, total_premium_money_amount.currency
    proposed_insurance[:insured_amount] = insured_amount
    proposed_insurance[:currency]       = currency

    proposed_insurance[:simple_insurance_product] = from_insurance_product
    proposed_insurance[:client]                   = on_client
    proposed_insurance[:lending]                  = on_loan if on_loan
    insurance_policy = create(proposed_insurance)
    raise Errors::DataError, insurance_policy.errors.first.first unless insurance_policy.saved?
    insurance_policy.setup_insurance_premium_fee
    insurance_policy
  end

  def administered_at_id
    administered_at = ClientAdministration.get_administered_at(self.client, self.proposed_on)
    administered_at ? administered_at.id : nil
  end

  def accounted_at_id
    accounted_at = ClientAdministration.get_registered_at(self.client, self.proposed_on)
    accounted_at ? accounted_at.id : nil
  end

  def setup_insurance_premium_fee
    administered_at, accounted_at = self.administered_at_id, self.accounted_at_id
    raise Errors::InvalidConfigurationError, "Locations that the client is registered at or administered at were not found" unless (administered_at and accounted_at)
    proposed_on_date = self.proposed_on
    get_insurance_premium_fee_product.values.each { |premium|
      FeeInstance.register_fee_instance(premium, self, administered_at, accounted_at, proposed_on_date)
    }
  end

  def get_insurance_premium_fee_product
    SimpleFeeProduct.get_applicable_premium_on_insurance_product(self.simple_insurance_product.id)
  end

end
