module Resolver

  # To be obsoleted, and is just returning center for now
  def self.resolve_location(for_location)
    [:center, for_location.id]
  end

  # Returns a constant for the counterparty type and the counterparty ID
  def self.resolve_counterparty(for_counterparty)
    klass_name = for_counterparty.class.name
    counterparty_type = Constants::Transaction::MODELS_AND_COUNTERPARTIES[klass_name]
    raise ArgumentError, "Unable to recognize a counterparty that corresponds to the instance: #{for_counterparty}" if counterparty_type.nil?
    [counterparty_type, for_counterparty.id]
  end

  def self.resolve_loan_assignment(for_assignment)
    klass_name = for_assignment.class.name
    loan_assignment_type = Constants::LoanAssignment::MODELS_AND_ASSIGNMENTS[klass_name]
    raise ArgumentError, "Unable to recognize a loan assignment that corresponds to the instance #{for_assignment}" unless loan_assignment_type
    [loan_assignment_type, for_assignment.id]
  end

  def self.fetch_assignment(by_assignment_type, for_assignment_id)
    Validators::Arguments.not_nil?(by_assignment_type, for_assignment_id)
    klass_name = Constants::LoanAssignment::ASSIGNMENT_AND_MODELS[by_assignment_type]
    raise ArgumentError, "Unable to recognize a model that corresponds to the loan assignment: #{by_assignment_type}" unless klass_name
    klass = Kernel.const_get(klass_name)
    klass.get(for_assignment_id)
  end

  # Verifies that the object is an instance of known counterparties
  def self.is_a_counterparty?(obj_to_test)
    Constants::Transaction::COUNTERPARTIES_AND_MODELS.values.include?(obj_to_test.class.name)
  end

  # Given a counterparty type and id, fetches the instance
  def self.fetch_counterparty(by_type, for_id)
    Validators::Arguments.not_nil?(by_type, for_id)
    klass_name = Constants::Transaction::COUNTERPARTIES_AND_MODELS[by_type]
    raise ArgumentError, "Unable to recognize a model that corresponds to the counterparty: #{by_type}" if klass_name.nil?
    klass = Kernel.const_get(klass_name)
    klass.get(for_id)
  end

  # Given a product type and id, fetches the product
  def self.fetch_product_instance(by_type, for_id)
    Validators::Arguments.not_nil?(by_type, for_id)
    klass = Constants::Products::PRODUCTS_AND_MODELS[by_type]
    raise ArgumentError, "Unable to recognize a model that corresponds to the financial product: #{by_type}" if klass.nil?
    klass.get(for_id)
  end

end
