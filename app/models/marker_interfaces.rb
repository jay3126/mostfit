module MarkerInterfaces
  
  # A marker interface is a module that (usually) does not provide any methods to mixin
  # It however specifies that classes that include the module
  # must respond in certain ways

  # Certain business models have events that recur at a certain frequency
  # Loan products and loans have recurring installments, center meetings recur
  # at a particular meeting frequency, and so on
  module Recurrence
    NOT_DEFINED = :not_defined
    DAILY = :daily; WEEKLY = :weekly; BIWEEKLY = :biweekly; MONTHLY = :monthly
    FREQUENCIES = [DAILY, WEEKLY, BIWEEKLY, MONTHLY]
    REPAYMENT_FREQUENCY = [NOT_DEFINED, WEEKLY, BIWEEKLY, MONTHLY]
    REPAYMENT_FREQUENCIES = REPAYMENT_FREQUENCY - [NOT_DEFINED]
    ACCOMODATES_FREQUENCIES = {
      DAILY => [WEEKLY, BIWEEKLY, MONTHLY],
      WEEKLY => [BIWEEKLY],
      BIWEEKLY => [],
      MONTHLY => []
    }
    FREQUENCIES_AS_PSEUDO_DAYS =
      { DAILY => 1, WEEKLY => 7, BIWEEKLY => 14, MONTHLY => 30}

    # All models that include this module must define a single no-argument method
    # "frequency" that returns a value
    # from MarkerInterfaces::Recurrence::FREQUENCIES as follows

    # In other words,
    # if instance.is_a? MarkerInterfaces::Recurrence
    #   assert instance.respond_to? :frequency
    # end
    
=begin
    def frequency
      # Return a value from MarkerInterfaces::Recurrence::FREQUENCIES
    end
=end

    # Answers whether the frequency of reccurence can 'accomodate' another
    # frequency of recurrence
    def can_accomodate?(other_frequency)
      my_frequency = self.frequency
      return true if my_frequency == other_frequency
      frequencies_accomodated = ACCOMODATES_FREQUENCIES[my_frequency]
      frequencies_accomodated.include?(other_frequency)
    end

    # Given a list of frequencies, it returns a list of all frequencies that
    # frequencies in the given list can accomodate
    def self.accomodated_frequencies(for_frequencies)
      accomodated_frequencies = for_frequencies.collect { |frequency| ACCOMODATES_FREQUENCIES[frequency] }
      sort_frequencies((accomodated_frequencies + for_frequencies).flatten.uniq)
    end

    def self.sort_frequencies(frequencies_ary)
      frequencies_ary.sort_by { |frequency| FREQUENCIES_AS_PSEUDO_DAYS[frequency] }
    end

  end
    
end
