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

  # The days of the week that are not business days
  def non_working_days
    [SATURDAY, SUNDAY]
  end

  # Returns the days of the week that are business days
  def business_days
    DAYS_OF_THE_WEEK - non_working_days
  end

  # Given some date, returns a Range with the earliest and latest permissible business dates in the month
  def monthly_business_date_range(example_date_in_month_and_year)
    month = example_date_in_month_and_year.month
    year  = example_date_in_month_and_year.year
    earliest_date = Date.new(year, month, Constants::Time::EARLIEST_BUSINESS_DATE_EACH_MONTH)
    earliest_business_date = today_or_next_business_day(earliest_date)

    latest_date = Date.new(year, month, Constants::Time::LAST_BUSINESS_DATE_EACH_MONTH)
    latest_business_date = today_or_previous_business_day(latest_date)
    raise Errors::InvalidConfigurationError, "Earliest date #{earliest_business_date} must precede latest date #{latest_business_date}" unless earliest_business_date < latest_business_date
    #TODO: take out holidays at the beginning and at the end
    earliest_business_date..latest_business_date
  end

  # Returns a list of the permitted business days in a month
  def permitted_business_days_in_month(example_date_in_month_and_year)
    business_date_range = monthly_business_date_range(example_date_in_month_and_year)
    permitted_business_days = []
    business_date_range.each { |date|
      permitted_business_days.push(date) if is_business_day?(date)
    }
    permitted_business_days
  end

  # Returns the date if it is a business day or the next business day
  def today_or_next_business_day(for_date)
    next_business_day(for_date - 1)
  end

  # Returns the date if it is a business day or the previous business day
  def today_or_previous_business_day(for_date)
    previous_business_day(for_date + 1)
  end

  # Returns the next business day for date
  def next_business_day(for_date)
    next_day = for_date + 1
    is_business_day?(next_day) ? next_day : next_business_day(next_day)
  end

  # Returns the previous business day for date
  def previous_business_day(for_date)
    previous_day = for_date - 1
    is_business_day?(previous_day) ? previous_day : previous_business_day(previous_day)
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

   def get_age_limit_for_credit
    [18, 55]
  end

  # Whether multiple lending is allowed
  def allow_multiple_loans?
    false
  end

  def regulation_total_loans_allowed
    2
  end

  def regulation_total_oustanding_allowed
    @regulation_total_outstanding_allowed ||= Money.new(5000000, Constants::Money::INR)
  end

  def available_loan_products(on_date = Date.today)  
    LendingProduct.all
  end
  
end
