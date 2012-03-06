class ConfigurationFacade
  include Singleton

  def get_age_limit_for_credit
    [18, 55]
  end

  def allow_multiple_loans?
    true
  end

end