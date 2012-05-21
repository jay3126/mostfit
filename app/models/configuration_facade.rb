require 'singleton'
require 'date'

# Access all configuration application-wide using the ConfigurationFacade
class ConfigurationFacade
  include Singleton
  include Constants::Time

  attr_reader :created_at

  def initialize
    @created_at = DateTime.now
  end

  # Returns the lower and upper age limit that is legally permissible for credit
  def get_age_limit_for_credit
    [18, 55]
  end

  # Whether multiple lending is allowed
  def allow_multiple_loans?
    true
  end

  # The days of the week that are not business days
  def non_working_days
    [SUNDAY]
  end

  # Returns the days of the week that are business days
  def business_days
    DAYS_OF_THE_WEEK - non_working_days
  end

  # Tests a date for whether it falls on a business day of the week
  def is_business_day?(date)
    weekday = Constants::Time.get_week_day(date)
    business_days.include?(weekday)
  end

  def default_currency
    Constants::Money::DEFAULT_CURRENCY
  end

  def default_locale
    Constants::Money::DEFAULT_LOCALE
  end

end
