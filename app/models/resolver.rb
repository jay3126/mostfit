module Resolver

  def self.fetch_counterparty(by_type, for_id)
    Validators::Arguments.not_nil?(by_type, for_id)
    klass = Constants::Transaction::COUNTERPARTIES_AND_MODELS[by_type]
    raise ArgumentError, "Unable to recognize a model that corresponds to the counterparty: #{by_type}" if klass.nil?
    klass.get(for_id)
  end

  def self.fetch_product_instance(by_type, for_id)
    Validators::Arguments.not_nil?(by_type, for_id)
    klass = Constants::Products::PRODUCTS_AND_MODELS[by_type]
    raise ArgumentError, "Unable to recognize a model that corresponds to the financial product: #{by_type}" if klass.nil?
    klass.get(for_id)
  end

end
