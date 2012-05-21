module DataMapper
  module Resource

    # Returns a hash that has the properties for money amounts as keys and instances of Money as values
    def to_money
      raise Errors::OperationNotSupportedError, "Does not store money amounts" unless ((self.respond_to?(:currency)) and
          (self.respond_to?(:money_amounts)) and (not (self.money_amounts.empty?)))
      money_values_hash = {}
      currency = self.currency
      money_amounts.each { |money_amount_sym| 
        amount_val = self.send(money_amount_sym)
        next unless amount_val
        money = Money.new(amount_val.to_i, currency)
        money_values_hash[money_amount_sym] = money
      }
      money_values_hash
    end

    # Uses the currency on the instance to return an instance of Money for any amount (usually one of the properties on the model)
    def to_money_amount(amount_in_least_terms_only)
      raise Errors::OperationNotSupportedError, "Does not have a value for currency" unless ((self.respond_to?(:currency)) and
          (self.currency))
      Money.new(amount_in_least_terms_only.to_i, self.currency)
    end

  end
end
