class ConfigurationFacade
  include Singleton

  def get_age_limit_for_credit
    [18, 55]
  end

  def allow_multiple_loans?
    false
  end

  def regulation_total_loans_allowed
    2
  end

  def regulation_total_oustanding_allowed
    50000
  end

end