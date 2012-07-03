module Validators
  module Assignments
   
    # Validates that the date of effective date of assignment is after the date of creation of any of the items to be assigned
    def self.is_valid_assignment_date?(effective_on, *to_be_assigned)
      if (to_be_assigned.length == 1)
        item = to_be_assigned.first
        test_val = effective_on < item.created_on ? [false, "#{item.to_s} created #{item.created_on}" + " has a creation date later than #{effective_on}"] :
            true
        return test_val
      else
        items_created_later = to_be_assigned.select {|item| effective_on < item.created_on}
        return true if items_created_later.empty?
        validation_message = ""
        first_element = true
        items_created_later.each {|item|
          validation_message += " and " unless first_element
          validation_message += "#{item.to_s} created #{item.created_on}"
          first_element = false
        }
        validation_message += " has a creation date later than #{effective_on}"
        return [false, validation_message]
      end
      true
    end

  end
end
