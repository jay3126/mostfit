module Validators

  module Arguments

    # Validates that none of the arguments are nil
    def self.not_nil?(*arg)
      arg.each { |argument|
        raise ArgumentError, "#{argument} is null" if argument.nil?
      }
    end

  end

  module Amounts

    # Validates that none of the arguments are nil or negative
    def self.is_positive?(*amount)
      amount.each { |amt|
        raise ArgumentError, "amount is not specified" unless amt
        raise ArgumentError, "amount is not a number" unless amt.is_a?(Numeric)
        raise ArgumentError, "amount: #{amt} is negative" if amt < 0
      }
    end

  end

end
