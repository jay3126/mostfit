module Constants

  module Center

    CENTER_CATEGORIES = ['','urban','rural']

  end

  module Client

    RELIGIONS = ['Hindu','Muslim','Sikh','Christian','Jain','Buddha']
    CASTES = ['General','SC','ST','OBC']
  end

  # points in time	
  module Time
    
    MEETING_FREQUENCIES = 
      [MarkerInterfaces::Recurrence::DAILY, MarkerInterfaces::Recurrence::WEEKLY, MarkerInterfaces::Recurrence::BIWEEKLY, MarkerInterfaces::Recurrence::MONTHLY]
    MEETING_FREQUENCIES_AS_DAYS = 
      { MarkerInterfaces::Recurrence::DAILY => 1, MarkerInterfaces::Recurrence::WEEKLY => 7, MarkerInterfaces::Recurrence::BIWEEKLY => 14 }

    EARLIEST_MEETING_HOURS_ALLOWED = 0; LATEST_MEETING_HOURS_ALLOWED = 23
    MEETING_HOURS_PERMISSIBLE_RANGE = Range.new(EARLIEST_MEETING_HOURS_ALLOWED, LATEST_MEETING_HOURS_ALLOWED)
    EARLIEST_MEETING_MINUTES_ALLOWED = 0; LATEST_MEETING_MINUTES_ALLOWED = 59
    MEETING_MINUTES_PERMISSIBLE_RANGE = Range.new(EARLIEST_MEETING_MINUTES_ALLOWED, LATEST_MEETING_MINUTES_ALLOWED)
    DEFAULT_FUTURE_MAX_DURATION_IN_DAYS = 366

    SUNDAY = :sunday; MONDAY = :monday; TUESDAY = :tuesday; WEDNESDAY = :wednesday; THURSDAY = :thursday; FRIDAY = :friday; SATURDAY = :saturday
    DAYS_OF_THE_WEEK = [SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY]

    TWELVE_HOUR_FORMAT = :am_pm_format; TWENTY_FOUR_HOUR_FORMAT = :twenty_four_hour_format
    DEFAULT_MEETING_TIME_FORMAT = TWELVE_HOUR_FORMAT
    TIME_FORMATS = [TWELVE_HOUR_FORMAT, TWENTY_FOUR_HOUR_FORMAT]

    # Returns the constant in the application for the day of the week
    def self.get_week_day(on_date)
      DAYS_OF_THE_WEEK[on_date.wday]
    end
    
    def self.get_next_date_for_day(weekday, on_or_after_date)
      raise ArgumentError, "Weekday not recognized: #{weekday}" unless DAYS_OF_THE_WEEK.include?(weekday)
      on_or_after_weekday = get_week_day(on_or_after_date)
      return on_or_after_date if on_or_after_weekday == weekday
      weekday_difference = DAYS_OF_THE_WEEK.index(weekday) - DAYS_OF_THE_WEEK.index(on_or_after_weekday)
      weekday_difference > 0 ? on_or_after_date + weekday_difference : on_or_after_date + (7 - weekday_difference.abs)
    end

  end

  # points in space
  module Space

    REGION = :region; AREA = :area; BRANCH = :branch; CENTER = :center

    LOCATIONS = [REGION, AREA, BRANCH, CENTER]
    LOCATION_IMMEDIATE_ANCESTOR = { CENTER => BRANCH, BRANCH => AREA, AREA => REGION }
    LOCATION_IMMEDIATE_DESCENDANT = { REGION => AREA, AREA => BRANCH, BRANCH => CENTER }
    MODELS_AND_LOCATIONS = { "Region" => REGION, "Area" => AREA, "Branch" => BRANCH, "Center" => CENTER }
    LOCATIONS_AND_MODELS = { REGION => 'Region', AREA => 'Area', BRANCH => 'Branch', CENTER => 'Center' }

    PROPOSED_MEETING_STATUS = 'proposed'; CONFIRMED_MEETING_STATUS = 'confirmed'; RESCHEDULED_MEETING_STATUS = 'rescheduled'
    MEETING_SCHEDULE_STATUSES = [PROPOSED_MEETING_STATUS, CONFIRMED_MEETING_STATUS, RESCHEDULED_MEETING_STATUS]

    MEETINGS_SUPPORTED_AT = [ CENTER ]

    def self.all_ancestors_for_type(location_type)
      ancestors = []
      anc = LOCATION_IMMEDIATE_ANCESTOR[location_type]
      while (not (anc.nil?))
        ancestors << anc
        anc = LOCATION_IMMEDIATE_ANCESTOR[anc]
      end
      ancestors
    end

    def self.all_descendants_for_type(location_type)
      descendants = []
      descend = LOCATION_IMMEDIATE_DESCENDANT[location_type]
      while (not (descend.nil?))
        descendants << descend
        descend = LOCATION_IMMEDIATE_DESCENDANT[descend]
      end
      descendants
    end

    # resolves the instance to a constant symbol using the class name
    def self.to_location_type(location_obj)
      MODELS_AND_LOCATIONS[location_obj.class.name]
    end

    def self.to_klass(location_type)
      klass_name = LOCATIONS_AND_MODELS[location_type]
      klass_name ? Kernel.const_get(klass_name) : nil
    end

    def self.ancestor_type(location)
      LOCATION_IMMEDIATE_ANCESTOR[to_location_type(location)]
    end

    def self.all_ancestors(location)
      all_ancestors_for_type(to_location_type(location))
    end

    def self.descendant_type(location)
      LOCATION_IMMEDIATE_DESCENDANT[to_location_type(location)]
    end

    def self.descendant_association(location)
      descendant_type_name = descendant_type(location)
      descendant_type_name.nil? ? nil : descendant_type_name.to_s.pluralize
    end

    def self.all_descendants(location)
      all_descendants_for_type(to_location_type(location))
    end

  end

  module Locations

    CENTER = :center
    MODELS_AND_LOCATIONS = { "Center" => CENTER }
    LOCATIONS = [CENTER]

    LOCATION_LEVELS = [1, 2, 3, 4]

  end

  module Status

    LOAN_APPLIED_STATUS = :loan_applied; LOAN_APPROVED_STATUS = :loan_approved
    LOAN_STATUSES = [LOAN_APPLIED_STATUS, LOAN_APPROVED_STATUS]

  end

  module Clients

    CLIENT = :client
    MODELS_AND_CLIENTS = { "Client" => CLIENT }
    CLIENTS = [CLIENT]
  end

  module Products

    LOAN = :loan
    MODELS_AND_PRODUCTS = { "Loan" => LOAN }
    PRODUCTS = [LOAN]

  end

  module Money

    INR = :INR; INR_MULTIPLIER = 100
    DEFAULT_CURRENCY = INR
    CURRENCIES = [INR]
    CURRENCIES_LEAST_UNITS_MULTIPLIERS = { INR => INR_MULTIPLIER }

    PAYMENT = :payment; RECEIPT = :receipt
    RECEIVED_OR_PAID = [RECEIPT, PAYMENT]

    LOAN = :loan
    TRANSACTED_PRODUCTS = [LOAN]

    CLIENT = :client
    COUNTERPARTIES = [CLIENT]

    TRANSACTION_AT_CENTER = :center
    TRANSACTION_LOCATIONS = [TRANSACTION_AT_CENTER]

    PRINCIPAL_DISBURSED = :principal_disbursed
    PRINCIPAL_REPAID = :principal_repaid; INTEREST_RECEIVED = :interest_received; FEE_INCOME = :fee_income; ADVANCE_RECEIPT = :advance_receipt
    ALLOCATIONS = [PRINCIPAL_DISBURSED, PRINCIPAL_REPAID, INTEREST_RECEIVED, FEE_INCOME, ADVANCE_RECEIPT]

  end

end