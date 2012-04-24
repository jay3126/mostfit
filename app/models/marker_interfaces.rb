module MarkerInterfaces
  
  # A marker interface is a module that does not provide any methods to mixin
  # It however specifies that classes that include the module
  # must respond in certain ways

  # Certain business models have events that recur at a certain frequency
  # Loan products and loans have recurring installments, center meetings recur
  # at a particular meeting frequency, and so on
  module Recurrence

    DAILY = :daily; WEEKLY = :weekly; BIWEEKLY = :biweekly; MONTHLY = :monthly
    FREQUENCIES = [DAILY, WEEKLY, BIWEEKLY, MONTHLY]

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
  end
    
end
