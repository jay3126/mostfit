class LoanAdministration
  include DataMapper::Resource
  include Constants::Properties, Constants::Loan

  property :id,              Serial
  property :loan_id,         *INTEGER_NOT_NULL
  property :administered_at, *INTEGER_NOT_NULL
  property :accounted_at,    *INTEGER_NOT_NULL
  property :effective_on,    *DATE_NOT_NULL
  property :performed_by,    *INTEGER_NOT_NULL
  property :recorded_by,     *INTEGER_NOT_NULL
  property :created_at,      *CREATED_AT

  validates_with_method :unique_assignment_on_date?

  # Validates that assignment of a loan is unique on any given date
  def unique_assignment_on_date?
    any_other_administration_on_date = LoanAdministration.all(:effective_on => self.effective_on, :loan_id => self.loan_id)
    any_other_administration_on_date.empty? ? true : [false, "A loan can only be assigned a single set of administered and accounted locations on any given date"]
  end

  def loan; Lending.get(self.loan_id); end
  def administered_at_location; BizLocation.get(self.administered_at); end
  def accounted_at_location; BizLocation.get(self.accounted_at); end
  def performed_by_staff; Staff.get(self.performed_by); end
  def recorded_by_user; User.get(self.recorded_by); end

  # Assigns an administration location and accounted_at location to a loan on the specified date
  def self.assign(administered_at, accounted_at, to_loan, performed_by, recorded_by, effective_on = Date.today)
    raise ArgumentError, "Locations to be assigned must be instances of BizLocation" unless (administered_at.is_a?(BizLocation) and accounted_at.is_a?(BizLocation))
    raise ArgumentError, "#{to_loan} provided for assignment is not a loan" unless (to_loan.is_a?(Lending))
    assignment = {}
    assignment[:administered_at] = administered_at.id
    assignment[:accounted_at]    = accounted_at.id
    assignment[:loan_id]         = to_loan.id
    assignment[:performed_by]    = performed_by
    assignment[:recorded_by]     = recorded_by
    assignment[:effective_on]    = effective_on
    loan_administration = create(assignment)
    raise Errors::DataError, loan_administration.errors.first.first unless loan_administration.saved?
    loan_administration
  end

  # Gets the location the loan was administered at as on the specified date
  def self.get_administered_at(loan_id, on_date = Date.today)
    locations = get_locations(loan_id, on_date)
    locations ? locations[ADMINISTERED_AT] : nil
  end

  # Gets the location that the loan was accounted at as on the specified date
  def self.get_accounted_at(loan_id, on_date = Date.today)
    locations = get_locations(loan_id, on_date)
    locations ? locations[ACCOUNTED_AT] : nil
  end

  # Produces a map with the administered and accounted locations
  def to_location_map
    { ADMINISTERED_AT => administered_at_location,
      ACCOUNTED_AT => accounted_at_location }
  end

  # Retrieves the administered_at and accounted_at locations for a given loan on the specified date
  def self.get_locations(for_loan_id, on_date = Date.today)
    locations                    = { }
    locations[:loan_id]          = for_loan_id
    locations[:effective_on.lte] = on_date
    locations[:order]            = [:effective_on.desc]
    recent_assignment            = first(locations)
    recent_assignment ? recent_assignment.to_location_map : nil
  end

  # Returns an (empty) list of loans administered at a location
  def self.get_loans_administered(at_location_id, on_date = Date.today)
    get_loans_at_location(ADMINISTERED_AT, at_location_id, on_date)
  end

  # Returns an (empty) list of loans administered at a location for a date range.
  def self.get_loans_administered_for_date_range(at_location_id, on_date = Date.today, till_date = on_date)
    get_loans_at_location_for_date_range(ADMINISTERED_AT, at_location_id, on_date, till_date)
  end

  # Returns an (empty) list of loans accounted at a location
  def self.get_loans_accounted(at_location_id, on_date = Date.today)
    get_loans_at_location(ACCOUNTED_AT, at_location_id, on_date)
  end

  # Returns an (empty) list of loans accounted at a location for a date range.
  def self.get_loans_accounted_for_date_range(at_location_id, on_date = Date.today, till_date = on_date)
    get_loans_at_location_for_date_range(ACCOUNTED_AT, at_location_id, on_date, till_date)
  end

  private

  # Returns the locations (per administered/accounted choice) at the given location (by id) as on the specified date
  def self.get_loans_at_location(administered_or_accounted_choice, given_location_id, on_date = Date.today)
    loans                                       = []
    locations                                   = { }
    locations[administered_or_accounted_choice] = given_location_id
    locations[:effective_on.lte]                = on_date
    administration                              = all(locations)
    given_location                              = BizLocation.get(given_location_id)
    administration.each { |each_admin|
      loan = each_admin.loan

      if administered_or_accounted_choice == ADMINISTERED_AT
        loans.push(loan) if (given_location == each_admin.administered_at_location)
      end

      if administered_or_accounted_choice == ACCOUNTED_AT
        loans.push(loan) if (given_location == each_admin.accounted_at_location)
      end
    }
    loans.uniq
  end

  # Returns the locations (per administered/accounted choice) at the given location (by id) for a date range.
  def self.get_loans_at_location_for_date_range(administered_or_accounted_choice, given_location_id, on_date = Date.today, till_date = on_date)
    loans                                       = []
    locations                                   = { }
    locations[administered_or_accounted_choice] = given_location_id
    locations[:effective_on.gte]                = on_date
    locations[:effective_on.lte]                = till_date
    administration                              = all(locations)
    given_location                              = BizLocation.get(given_location_id)
    administration.each { |each_admin|
      loan = each_admin.loan

      if administered_or_accounted_choice == ADMINISTERED_AT
        loans.push(loan) if (given_location == each_admin.administered_at_location)
      end

      if administered_or_accounted_choice == ACCOUNTED_AT
        loans.push(loan) if (given_location == each_admin.accounted_at_location)
      end
    }
    loans.uniq
  end

end
