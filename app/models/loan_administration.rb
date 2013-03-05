class LoanAdministration
  include DataMapper::Resource
  include Constants::Properties, Constants::Loan, LoanLifeCycle

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

  def self.get_location_map(for_loan_id, on_date = Date.today)
    locations                    = { }
    locations[:loan_id]          = for_loan_id
    locations[:effective_on.lte] = on_date
    locations[:order]            = [:effective_on.desc]
    first(locations)
  end

  # Retrieves the administered_at and accounted_at locations for a given loan on the specified date
  def self.get_locations(for_loan_id, on_date = Date.today)
    recent_assignment = get_location_map(for_loan_id)
    recent_assignment ? recent_assignment.to_location_map : nil
  end

  # Returns an (empty) list of loans administered at a location
  def self.get_loans_administered(at_location_id, on_date = Date.today)
    get_loans_at_location(ADMINISTERED_AT, at_location_id, on_date)
  end

  def self.get_loans_administered_by_sql(at_location_id, on_date = Date.today, count = false, status = nil, funder_id = nil)
    loan_ids = get_loans_at_location_by_sql(ADMINISTERED_AT, at_location_id, on_date, count, status, funder_id)
    loan_ids.blank? ? [] : Lending.all(:id => loan_ids)
  end

  def self.get_loan_ids_administered_by_sql(at_location_id, on_date = Date.today, count = false, status = nil, funder_id = nil)
    get_loans_at_location_by_sql(ADMINISTERED_AT, at_location_id, on_date, count, status, funder_id)
  end

  # Returns an (empty) list of loans administered at a location for a date range.
  def self.get_loans_administered_for_date_range(at_location_id, on_date = Date.today, till_date = on_date)
    get_loans_at_location_for_date_range(ADMINISTERED_AT, at_location_id, on_date, till_date)
  end

  # Returns an (empty) list of loans accounted at a location
  def self.get_loans_accounted(at_location_id, on_date = Date.today)
    get_loans_at_location(ACCOUNTED_AT, at_location_id, on_date)
  end

  def self.get_loans_accounted_by_sql(at_location_id, on_date = Date.today, count = false, status = nil, funder_id = nil)
    loan_ids = get_loans_at_location_by_sql(ACCOUNTED_AT, at_location_id, on_date, count, status, funder_id)
    loan_ids.blank? ? [] : Lending.all(:id => loan_ids)
  end

  def self.get_loan_ids_accounted_by_sql(at_location_id, on_date = Date.today, count = false, status = nil, funder_id = nil)
    get_loans_at_location_by_sql(ACCOUNTED_AT, at_location_id, on_date, count, status, funder_id)
  end

  def self.get_loan_ids_group_vise_accounted_by_sql(at_location_id, on_date = Date.today, funder_id = nil)
    get_loans_group_vise_at_location_by_sql(ACCOUNTED_AT, at_location_id, on_date, funder_id)
  end

  # Returns an (empty) list of loans accounted at a location for a date range by sql.
  def self.get_loans_accounted_for_date_range(at_location_id, on_date = Date.today, till_date = on_date, funder_id = nil)
    get_loans_at_location_for_date_range(ACCOUNTED_AT, at_location_id, on_date, till_date, funder_id)
  end

  # Returns an (empty) list of loans accounted at a location for a date range by sql.
  def self.get_loans_accounted_for_date_range_by_sql(at_location_id, on_date = Date.today, till_date = on_date, count = false, status = nil, funder_id = nil)
    loan_ids = get_loans_at_location_for_date_range_by_sql(ACCOUNTED_AT, at_location_id, on_date, till_date, count, status, funder_id)
    loan_ids.blank? ? [] : Lending.all(:id => loan_ids)
  end

  def self.get_loan_ids_accounted_for_date_range_by_sql(at_location_id, on_date = Date.today, till_date = on_date, count = false, status = nil, funder_id = nil)
    get_loans_at_location_for_date_range_by_sql(ACCOUNTED_AT, at_location_id, on_date, till_date, count, status, funder_id)
  end

  def self.get_loan_ids_group_vise_accounted_for_date_range_by_sql(at_location_id, on_date = Date.today, till_date = on_date, funder_id = nil)
    get_loans_group_vise_at_location_for_date_range_by_sql(ACCOUNTED_AT, at_location_id, on_date, till_date, funder_id)
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

  def self.get_loans_at_location_by_sql(administered_or_accounted_choice, given_location_id, on_date = Date.today, count = false, status = nil, funder_id = nil)
    locations                                   = given_location_id.class == Array ? given_location_id : [given_location_id]
    loan_ids                                    = locations.compact!.blank? ? [] : repository(:default).adapter.query("select a.loan_id from loan_administrations a inner join (select loan_id, max(id) max_id from loan_administrations where effective_on <= '#{on_date.strftime('%Y-%m-%d')}' group by loan_id) as b on a.id = b.max_id where a.#{administered_or_accounted_choice} IN (#{locations.join(',')});")
    loan_search                                 = {}
    if loan_ids.blank?
      count == true ? 0 : []
    else
      if count
        #l_links = repository(:default).adapter.query("select count(*) from (select * from loan_administrations where loan_id IN (#{loan_ids.join(',')})) la where la.#{administered_or_accounted_choice} = (select #{administered_or_accounted_choice} from (select * from loan_administrations where loan_id IN (#{loan_ids.join(',')})) la1 where la.loan_id = la1.loan_id AND la.#{administered_or_accounted_choice} IN (#{locations[administered_or_accounted_choice].join(',')}) order by la1.effective_on desc limit 1 );")
        loan_ids.blank? ? 0 : loan_ids.count
      else
        #l_links = repository(:default).adapter.query("select la.loan_id from (select * from loan_administrations where loan_id IN (#{loan_ids.join(',')})) la where la.#{administered_or_accounted_choice} = (select #{administered_or_accounted_choice} from (select * from loan_administrations where loan_id IN (#{loan_ids.join(',')})) la1 where la.loan_id = la1.loan_id AND la.#{administered_or_accounted_choice} IN (#{locations[administered_or_accounted_choice].join(',')}) order by la1.effective_on desc limit 1 );")
        l_links = loan_ids
        unless funder_id.blank?
          l_links = l_links.blank? ? [] : repository(:default).adapter.query("select a.lending_id from funding_line_additions a inner join (select lending_id, max(id) max_id from funding_line_additions where created_on <= '#{on_date.strftime('%Y-%m-%d')}' group by lending_id ) as b on a.id = b.max_id where a.lending_id in (#{l_links.join(',')}) and a.funder_id = #{funder_id};")
        end

        if status.blank?
          loan_search[:id] = l_links
        else
          loan_search[:status] = status
          status_key = LoanLifeCycle::LOAN_STATUSES.index(status.to_sym)
          loan_search[:id] = (l_links.blank? || status_key.blank?) ? [] : repository(:default).adapter.query("select lending_id from (select * from loan_status_changes where lending_id IN (#{l_links.join(',')})) s1 where s1.to_status = #{status_key+1} AND s1.to_status = (select to_status from loan_status_changes s2 where s2.lending_id = s1.lending_id AND s2.effective_on <= '#{on_date.strftime('%Y-%m-%d')}' ORDER BY s2.effective_on desc LIMIT 1);")
        end
        loan_search[:id].blank? ? [] : loan_search[:id]
      end
    end
  end

  def self.get_loans_group_vise_at_location_by_sql(administered_or_accounted_choice, given_location_id, on_date = Date.today, funder_id = nil)
    locations                                   = given_location_id.class == Array ? given_location_id : [given_location_id]
    loan_ids                                    = locations.compact!.blank? ? [] : repository(:default).adapter.query("select a.loan_id from loan_administrations a inner join (select loan_id, max(id) max_id from loan_administrations where effective_on <= '#{on_date.strftime('%Y-%m-%d')}' group by loan_id) as b on a.id = b.max_id where a.#{administered_or_accounted_choice} IN (#{locations.join(',')});")
    loans = {STATUS_NOT_SPECIFIED => [], NEW_LOAN_STATUS => [], APPROVED_LOAN_STATUS => [], REJECTED_LOAN_STATUS => [], DISBURSED_LOAN_STATUS => [], REPAID_LOAN_STATUS =>[], PRECLOSED_LOAN_STATUS => [], WRITTEN_OFF_LOAN_STATUS =>[]}
    if loan_ids.blank?
      loans
    else
      #l_loans = repository(:default).adapter.query("select loan_id from (select * from loan_administrations where loan_id IN (#{loan_ids.join(',')})) la where la.#{administered_or_accounted_choice} = (select #{administered_or_accounted_choice} from (select * from loan_administrations where loan_id IN (#{loan_ids.join(',')})) la1 where la.loan_id = la1.loan_id AND la.#{administered_or_accounted_choice} IN (#{locations[administered_or_accounted_choice].join(',')}) order by la1.effective_on desc limit 1 );")
      l_loans = loan_ids
      unless funder_id.blank?
        l_loans = l_loans.blank? ? [] : repository(:default).adapter.query("select a.lending_id from funding_line_additions a inner join (select lending_id, max(id) max_id from funding_line_additions where created_on <= '#{on_date.strftime('%Y-%m-%d')}' group by lending_id ) as b on a.id = b.max_id where a.lending_id in (#{l_loans.join(',')}) and a.funder_id = #{funder_id};")
      end
      loan_id_status = l_loans.blank? ? [] : repository(:default).adapter.query("select a.lending_id, a.to_status from (select * from loan_status_changes x where x.lending_id IN (#{l_loans.join(',')})) a where (a.to_status, a.lending_id) = (select b.to_status,b.lending_id from loan_status_changes b where b.lending_id = a.lending_id and b.effective_on <= '#{on_date.strftime("%Y-%m-%d")}' order by b.effective_on desc limit 1 );")
      unless loan_id_status.blank?
        loans_by_group                 = loan_id_status.group_by{|s| s.to_status}
        loans[STATUS_NOT_SPECIFIED]    = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:status_not_specified)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:status_not_specified)+1].map(&:lending_id)
        loans[NEW_LOAN_STATUS]         = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:new_loan_status)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:new_loan_status)+1].map(&:lending_id)
        loans[APPROVED_LOAN_STATUS]    = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:approved_loan_status)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:approved_loan_status)+1].map(&:lending_id)
        loans[REJECTED_LOAN_STATUS]    = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:rejected_loan_status)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:rejected_loan_status)+1].map(&:lending_id)
        loans[DISBURSED_LOAN_STATUS]   = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:disbursed_loan_status)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:disbursed_loan_status)+1].map(&:lending_id)
        loans[REPAID_LOAN_STATUS]      = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:repaid_loan_status)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:repaid_loan_status)+1].map(&:lending_id)
        loans[PRECLOSED_LOAN_STATUS]   = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:preclosed_loan_status)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:preclosed_loan_status)+1].map(&:lending_id)
        loans[WRITTEN_OFF_LOAN_STATUS] = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:written_off_loan_status)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:written_off_loan_status)+1].map(&:lending_id)
      end
      loans
    end
  end

  def self.get_loans_group_vise_at_location_for_date_range_by_sql(administered_or_accounted_choice, given_location_id, from_date = Date.today, till_date = Date.today, funder_id = nil)
    locations                                   = given_location_id.class == Array ? given_location_id : [given_location_id]
    loan_ids                                    = locations.compact!.blank? ? [] : repository(:default).adapter.query("select a.loan_id from loan_administrations a inner join (select loan_id, max(id) max_id from loan_administrations where effective_on <= '#{till_date.strftime('%Y-%m-%d')}' group by loan_id) as b on a.id = b.max_id where a.#{administered_or_accounted_choice} IN (#{locations.join(',')});")
    loans = {STATUS_NOT_SPECIFIED => [], NEW_LOAN_STATUS => [], APPROVED_LOAN_STATUS => [], REJECTED_LOAN_STATUS => [], DISBURSED_LOAN_STATUS => [], REPAID_LOAN_STATUS =>[], PRECLOSED_LOAN_STATUS => [], WRITTEN_OFF_LOAN_STATUS =>[]}
    if loan_ids.blank?
      loans
    else
      # l_loans = repository(:default).adapter.query("select loan_id from (select * from loan_administrations where loan_id IN (#{loan_ids.join(',')})) la where la.#{administered_or_accounted_choice} = (select #{administered_or_accounted_choice} from (select * from loan_administrations where loan_id IN (#{loan_ids.join(',')})) la1 where la.loan_id = la1.loan_id AND la.#{administered_or_accounted_choice} IN (#{locations[administered_or_accounted_choice].join(',')}) order by la1.effective_on desc limit 1 );")
      l_loans = loan_ids
      unless funder_id.blank?
        l_loans = l_loans.blank? ? [] : repository(:default).adapter.query("select a.lending_id from funding_line_additions a inner join (select lending_id, max(id) max_id from funding_line_additions where created_on <= '#{till_date.strftime('%Y-%m-%d')}' group by lending_id ) as b on a.id = b.max_id where a.lending_id in (#{l_loans.join(',')}) and a.funder_id = #{funder_id};")
      end
      loan_id_status = l_loans.blank? ? [] : repository(:default).adapter.query("select a.lending_id, a.to_status from (select * from loan_status_changes x where x.lending_id IN (#{l_loans.join(',')})) a where (a.to_status, a.lending_id) = (select b.to_status,b.lending_id from loan_status_changes b where b.lending_id = a.lending_id and (b.effective_on >= '#{from_date.strftime("%Y-%m-%d")}' or b.effective_on <= '#{till_date.strftime("%Y-%m-%d")}') order by b.effective_on desc limit 1 );")
      unless loan_id_status.blank?
        loans_by_group                 = loan_id_status.group_by{|s| s.to_status}
        loans[STATUS_NOT_SPECIFIED]    = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:status_not_specified)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:status_not_specified)+1].map(&:lending_id)
        loans[NEW_LOAN_STATUS]         = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:new_loan_status)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:new_loan_status)+1].map(&:lending_id)
        loans[APPROVED_LOAN_STATUS]    = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:approved_loan_status)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:approved_loan_status)+1].map(&:lending_id)
        loans[REJECTED_LOAN_STATUS]    = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:rejected_loan_status)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:rejected_loan_status)+1].map(&:lending_id)
        loans[DISBURSED_LOAN_STATUS]   = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:disbursed_loan_status)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:disbursed_loan_status)+1].map(&:lending_id)
        loans[REPAID_LOAN_STATUS]      = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:repaid_loan_status)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:repaid_loan_status)+1].map(&:lending_id)
        loans[PRECLOSED_LOAN_STATUS]   = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:preclosed_loan_status)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:preclosed_loan_status)+1].map(&:lending_id)
        loans[WRITTEN_OFF_LOAN_STATUS] = loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:written_off_loan_status)+1].blank? ? [] : loans_by_group[LoanLifeCycle::LOAN_STATUSES.index(:written_off_loan_status)+1].map(&:lending_id)
      end
      loans
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

  def self.get_loans_at_location_for_date_range_by_sql(administered_or_accounted_choice, given_location_id, on_date, till_date, count = false, status = nil, funder_id = nil)
    loan_search                                 = {}
    locations                                   = given_location_id.class == Array ? given_location_id : [given_location_id]
    loan_ids                                    = locations.compact!.blank? ? [] : repository(:default).adapter.query("select a.loan_id from loan_administrations a inner join (select loan_id, max(id) max_id from loan_administrations where effective_on <= '#{till_date.strftime('%Y-%m-%d')}' group by loan_id) as b on a.id = b.max_id where a.#{administered_or_accounted_choice} IN (#{locations.join(',')});")
    if loan_ids.blank?
      count == true ? 0 : []
    else
      if count
        #l_links = repository(:default).adapter.query("select count(*) from (select * from loan_administrations where loan_id IN (#{loan_ids.join(',')})) la where la.#{administered_or_accounted_choice} = (select #{administered_or_accounted_choice} from (select * from loan_administrations where loan_id IN (#{loan_ids.join(',')})) la1 where la.loan_id = la1.loan_id AND la.#{administered_or_accounted_choice} = '#{given_location_id}' order by la1.effective_on desc limit 1 );")
        l_links = loan_ids
        l_links.blank? ? 0 : l_links
      else
        #l_links = repository(:default).adapter.query("select loan_id from (select * from loan_administrations where loan_id IN (#{loan_ids.join(',')})) la where la.#{administered_or_accounted_choice} = (select #{administered_or_accounted_choice} from (select * from loan_administrations where loan_id IN (#{loan_ids.join(',')})) la1 where la.loan_id = la1.loan_id AND la.#{administered_or_accounted_choice} = '#{given_location_id}' order by la1.effective_on desc limit 1 );")
        l_links = loan_ids
        unless funder_id.blank?
          l_links = l_links.blank? ? [] : repository(:default).adapter.query("select a.lending_id from funding_line_additions a inner join (select lending_id, max(id) max_id from funding_line_additions where created_on <= '#{till_date.strftime('%Y-%m-%d')}' group by lending_id ) as b on a.id = b.max_id where a.lending_id in (#{l_links.join(',')}) and a.funder_id = #{funder_id};")
        end

        if status.blank?
          loan_search[:id] = l_links
        else
          loan_search[:status] = status
          status_key = LoanLifeCycle::LOAN_STATUSES.index(status.to_sym)
          loan_search[:id] = l_links.blank? || status_key.blank? ? [] : repository(:default).adapter.query("select lending_id from (select * from loan_status_changes where lending_id IN (#{l_links.join(',')})) s1 where s1.to_status = #{status_key+1} AND s1.to_status = (select to_status from loan_status_changes s2 where s2.lending_id = s1.lending_id AND (s2.effective_on >= '#{on_date.strftime('%Y-%m-%d')}' OR s2.effective_on <= '#{till_date.strftime('%Y-%m-%d')}') ORDER BY s2.effective_on desc LIMIT 1);")
        end
        l_links.blank? || loan_search[:id].blank? ? [] : loan_search[:id]
      end
    end
  end

end
