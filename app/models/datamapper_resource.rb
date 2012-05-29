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

    # Uses the currency on the instance to return an instance of Money for the specified money property on the model
    def to_money_amount(amount_property_name_sym)
      raise Errors::OperationNotSupportedError, "Does not have a value for currency" unless ((self.respond_to?(:currency)) and
          (self.currency))
      raise Errors::OperationNotSupportedError, "Does not have a property by the name #{amount_property_name_sym}" unless (self.respond_to?(amount_property_name_sym))
      amount_val = self.send(amount_property_name_sym)
      amount_val ? Money.new(amount_val.to_i, self.currency) : nil
    end

    # Returns a money amount of zero value for the currency on model instances that store money amounts
    def zero_money_amount
      raise Errors::OperationNotSupportedError, "Does not have a value for currency" unless ((self.respond_to?(:currency)) and
          (self.currency))
      cache = @zero_money_cache ||= {}
      cache[self.currency] ||= Money.zero_money_amount(self.currency)
    end

  end
end
