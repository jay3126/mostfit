module ClientValidations

  # This checks for multiple conditions including whether configuration allows multiple loans
  # and whether the age of client (if one can be computed) is as per permissible age for credit
  def new_loan_permitted?
    return false unless permissible_age_for_credit?
    return !(has_loans_oustanding?) unless ConfigurationFacade.instance.allow_multiple_loans?
    true
  end

  # Checks the age of the client against the permissible age for credit
  # If an age is not available on the client, it returns true
  def permissible_age_for_credit?
    age = nil
    age = person_age if (respond_to?(:person_age) and person_age)
    return false unless age

    lower_limit, upper_limit = ConfigurationFacade.instance.get_age_limit_for_credit
    # today = Date.today
    # active_support dates does not seem to work properly
    # oldest_dob = upper_limit.years.ago(today); youngest_dob = lower_limit.years.ago(today)
    # using an approximation for now, this will err on the younger side for both old and young,
    # but more for the older

    age <= upper_limit && age >= lower_limit ? true : [false, "Age should be greator than 18 and less than 55"]
  end

  # Iterates through loans and returns true if any are outstanding
  def has_loans_oustanding?
    if respond_to?(:loans) and loans
      any_oustanding = loans.any?{|ln| ln.get_status == Constants::Status::LOAN_OUTSTANDING_STATUS}
      return true if any_oustanding
    end
    false
  end

end

module PeopleValidations
  #Any object or model that is a 'human' can mix this in

  def person_age
    raise Errors::OperationNotSupportedError, "The instance does not have a value for age" unless (respond_to?(:date_of_birth) and date_of_birth.is_a?(Date))
    recorded_dob = date_of_birth
    raise StandardError, "There was no value available for date of birth" unless recorded_dob
    Date.today.year - recorded_dob.year
  end

end