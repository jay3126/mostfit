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
    if Mfi.first.system_state == :migration
      loan_administration = create!(assignment)
    else
      loan_administration = create(assignment)
      raise Errors::DataError, loan_administration.errors.first.first unless loan_administration.saved?
    end
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

  def self.get_loans_administered_by_sql(at_location_id, on_date = Date.today, count = false, status = nil)
    get_loans_at_location_by_sql(ADMINISTERED_AT, at_location_id, on_date, count, status)
  end

  # Returns an (empty) list of loans administered at a location for a date range.
  def self.get_loans_administered_for_date_range(at_location_id, on_date = Date.today, till_date = on_date)
    get_loans_at_location_for_date_range(ADMINISTERED_AT, at_location_id, on_date, till_date)
  end

  # Returns an (empty) list of loans accounted at a location
  def self.get_loans_accounted(at_location_id, on_date = Date.today)
    get_loans_at_location(ACCOUNTED_AT, at_location_id, on_date)
  end

  def self.get_loans_accounted_by_sql(at_location_id, on_date = Date.today, count = false, status = nil)
    get_loans_at_location_by_sql(ACCOUNTED_AT, at_location_id, on_date, count, status)
  end

  # Returns an (empty) list of loans accounted at a location for a date range by sql.
  def self.get_loans_accounted_for_date_range(at_location_id, on_date = Date.today, till_date = on_date)
    get_loans_at_location_for_date_range(ACCOUNTED_AT, at_location_id, on_date, till_date)
  end

  # Returns an (empty) list of loans accounted at a location for a date range by sql.
  def self.get_loans_accounted_for_date_range_by_sql(at_location_id, on_date = Date.today, till_date = on_date, count = false, status = nil)
    get_loans_at_location_for_date_range_by_sql(ACCOUNTED_AT, at_location_id, on_date, till_date, count, status)
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
        loans.push(loan) if (given_location == each_admin.administered_at_location and each_admin.administered_at_location == get_administered_at(each_admin.loan_id, on_date))
      end

      if administered_or_accounted_choice == ACCOUNTED_AT
        loans.push(loan) if (given_location == each_admin.accounted_at_location and each_admin.accounted_at_location == get_accounted_at(each_admin.loan_id, on_date))
      end
    }
    loans.uniq
  end

  def self.get_loans_at_location_by_sql(administered_or_accounted_choice, given_location_id, on_date = Date.today, count = false, status = nil)
    locations                                   = {}
    loan_search                                 = {}
    locations[administered_or_accounted_choice] = given_location_id.class == Array ? given_location_id : [given_location_id]
    locations[:effective_on.lte]                = on_date
    administration                              = all(locations)
    if administration.blank?
      count == true ? 0 : []
    else
      if count
        l_links = repository(:default).adapter.query("select count(*) from (select * from loan_administrations where loan_id IN (#{administration.map(&:loan_id).join(',')})) la where la.#{administered_or_accounted_choice} = (select #{administered_or_accounted_choice} from (select * from loan_administrations where loan_id IN (#{administration.map(&:loan_id).join(',')})) la1 where la.loan_id = la1.loan_id AND la.#{administered_or_accounted_choice} IN (#{locations[administered_or_accounted_choice].join(',')}) order by la1.effective_on desc limit 1 );")
        l_links.blank? ? 0 : l_links
      else
        l_links = repository(:default).adapter.query("select * from (select * from loan_administrations where loan_id IN (#{administration.map(&:loan_id).join(',')})) la where la.#{administered_or_accounted_choice} = (select #{administered_or_accounted_choice} from (select * from loan_administrations where loan_id IN (#{administration.map(&:loan_id).join(',')})) la1 where la.loan_id = la1.loan_id AND la.#{administered_or_accounted_choice} IN (#{locations[administered_or_accounted_choice].join(',')}) order by la1.effective_on desc limit 1 );")
        if status.blank?
          loan_search[:id] = l_links.map(&:loan_id)
        else
          loan_search[:status] = status
          status_key = LoanLifeCycle::LOAN_STATUSES.index(status.to_sym)
          loan_search[:id] = status_key.blank? ? [0] : repository(:default).adapter.query("select lending_id from (select * from loan_status_changes where lending_id IN (#{l_links.map(&:loan_id).join(',')})) s1 where s1.to_status = #{status_key+1} AND s1.to_status = (select to_status from loan_status_changes s2 where s2.lending_id = s1.lending_id AND s2.effective_on <= '#{on_date.strftime("%Y-%m-%d")}' ORDER BY s2.effective_on desc LIMIT 1);")
        end

        l_links.map(&:loan_id).blank? ? [] : Lending.all(loan_search)
      end
    end
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
        loans.push(loan) if (given_location == each_admin.administered_at_location and each_admin.administered_at_location == get_administered_at(each_admin.loan_id, on_date))
      end

      if administered_or_accounted_choice == ACCOUNTED_AT
        loans.push(loan) if (given_location == each_admin.accounted_at_location and each_admin.accounted_at_location == get_accounted_at(each_admin.loan_id, on_date))
      end
    }
    loans.uniq
  end

  def self.get_loans_at_location_for_date_range_by_sql(administered_or_accounted_choice, given_location_id, on_date, till_date, count = false, status = nil)
    locations                                   = {}
    loan_search                                 = {}
    locations[administered_or_accounted_choice] = given_location_id
    locations[:effective_on.lte]                = till_date
    administration                              = all(locations)
    if administration.blank?
      count == true ? 0 : []
    else
      if count
        l_links = repository(:default).adapter.query("select count(*) from (select * from loan_administrations where loan_id IN (#{administration.map(&:loan_id).join(',')})) la where la.#{administered_or_accounted_choice} = (select #{administered_or_accounted_choice} from (select * from loan_administrations where loan_id IN (#{administration.map(&:loan_id).join(',')})) la1 where la.loan_id = la1.loan_id AND la.#{administered_or_accounted_choice} = '#{given_location_id}' order by la1.effective_on desc limit 1 );")
        l_links.blank? ? 0 : l_links
      else
        l_links = repository(:default).adapter.query("select loan_id from (select * from loan_administrations where loan_id IN (#{administration.map(&:loan_id).join(',')})) la where la.#{administered_or_accounted_choice} = (select #{administered_or_accounted_choice} from (select * from loan_administrations where loan_id IN (#{administration.map(&:loan_id).join(',')})) la1 where la.loan_id = la1.loan_id AND la.#{administered_or_accounted_choice} = '#{given_location_id}' order by la1.effective_on desc limit 1 );")
        if status.blank?
          loan_search[:id] = l_links
        else
          loan_search[:status] = status
          status_key = LoanLifeCycle::LOAN_STATUSES.index(status.to_sym)
          loan_search[:id] = status_key.blank? ? [0] : repository(:default).adapter.query("select lending_id from (select * from loan_status_changes where lending_id IN (#{l_links.join(',')})) s1 where s1.to_status = #{status_key+1} AND s1.to_status = (select to_status from loan_status_changes s2 where s2.lending_id = s1.lending_id AND (s2.effective_on >= '#{on_date.strftime("%Y-%m-%d")}' OR s2.effective_on <= '#{till_date.strftime("%Y-%m-%d")}') ORDER BY s2.effective_on desc LIMIT 1);")
        end
        l_links.blank? || loan_search[:id].blank? ? [] : Lending.all(loan_search)
      end
    end
  end

end
