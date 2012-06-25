module Validators
  module Assignments
   
    # Validates that the date of effective date of assignment does not precede the date of creation of any of the items participating in assignment
    def self.is_valid_assignment_date?(effective_on, *to_be_assigned)
      any_item_created_later = *to_be_assigned.any? {|item| effective_on < item.created_on}
      any_item_created_later ? [false, "Some of the items to be assigned were created after #{effective_on}"] : 
        true
    end

  end
end
