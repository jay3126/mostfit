class LocationMerge
  include DataMapper::Resource
  include Constants::Properties
  include Comparable
  include Constants::ProcessVerificationStatus

  property :id,                     Serial
  property :merged_location_id,     *INTEGER_NOT_NULL
  property :merge_into_location_id, *INTEGER_NOT_NULL
  property :effective_on,           *DATE_NOT_NULL
  property :status,                 Enum.send('[]', *VERIFICATION_STATUSES), :nullable => false, :default => PENDING
  property :started_time,           *CREATED_AT
  property :completed_time,         DateTime
  property :performed_by,           *INTEGER_NOT_NULL
  property :recorded_by,            *INTEGER_NOT_NULL
  property :created_at,             *CREATED_AT

  belongs_to :biz_location, :child_key => [:merged_location_id]
  belongs_to :staff_member, :child_key => [:performed_by], :model => 'StaffMember'

  validates_with_method :check_merge_location?

  def check_merge_location?
    obj = first(:status => COMPLETED, :merged_location_id => [self.merged_location_id, self.merge_into_location_id])
    obj.blank? ? true : [false, "Location merged already"]
  end

  def self.merge_to_location(merge_location, merge_into_location, effective_on, performed_by, recorded_by)
    obj_values = {}
    obj_values[:merged_location_id]     = merge_location.id
    obj_values[:merge_into_location_id] = merge_into_location.id
    obj_values[:effective_on]           = effective_on
    obj_values[:performed_by]           = performed_by
    obj_values[:recorded_by]            = recorded_by
    obj_values[:status]                 = IN_PROCESS

    obj = first_or_create(obj_values)
    raise Errors::DataError, obj.errors.first.first unless obj.saved?
    obj.perform_merge_to_location
    obj
  end

  def self.merge_roll_back_to_location(merge_location, merge_into_location, effective_on)
    obj = first(:status.not => COMPLETED, :merged_location_id => merge_location.id, :merge_into_location_id => merge_into_location.id, :effective_on => effective_on)
    obj.perform_merge_roll_back_to_location unless obj.blank?
  end

  def perform_merge_roll_back_to_location
    end_time = self.completed_time.blank? ? DateTime.now : self.completed_time
    LoanAdministration.all(:created_at.gte => self.started_time, :created_at.lte => end_time).destroy
    ClientAdministration.all(:created_at.gte => self.started_time, :created_at.lte => end_time).destroy
    LocationLink.all(:created_at.gte => self.started_time, :created_at.lte => end_time).destroy
    LendingProductLocation.all(:created_at.gte => self.started_time, :created_at.lte => end_time).destroy
    StaffPosting.all(:created_at.gte => self.started_time, :created_at.lte => end_time).destroy
    AccountingLocation.all(:created_at.gte => self.started_time, :created_at.lte => end_time).destroy
  end

  def perform_merge_to_location
    merge_location = BizLocation.get(self.merged_location_id)
    merge_into_location = BizLocation.get(self.merge_into_location_id)
    effective_on = self.effective_on
    performed_by = self.performed_by
    recorded_by = self.recorded_by
    all_loan_merge(merge_location, merge_into_location, effective_on, performed_by, recorded_by)
    all_client_merge(merge_location, merge_into_location, effective_on, performed_by, recorded_by)
    all_center_merge(merge_location, merge_into_location, effective_on)
    all_loan_product_merge(merge_location, merge_into_location, effective_on, performed_by, recorded_by)
    all_staff_member_merge(merge_location, merge_into_location, effective_on, performed_by, recorded_by)
    all_accouting_merge(merge_location, merge_into_location, effective_on, performed_by, recorded_by)
  end

  def all_loan_merge(merge_location, merge_into_location, effective_on, performed_by, recorded_by)
    loans = get_location_facade(User.first).get_loans_accounted(merge_location.id, effective_on)
    loans.each do |loan|
      center = LoanAdministration.get_administered_at(loan.id, effective_on)
      LoanAdministration.assign(center, merge_into_location, loan, performed_by, recorded_by, effective_on)
    end
  end

  def all_client_merge(merge_location, merge_into_location, effective_on, performed_by, recorded_by)
    clients = ClientAdministration.get_clients_registered(merge_location.id, effective_on)
    clients.each do |client|
      center = ClientAdministration.get_current_administration(client)
      ClientAdministration.assign(center.administered_at_location, merge_into_location, client, performed_by, recorded_by, effective_on) if Client.is_client_active?(client)
    end
  end

  def all_center_merge(merge_location, merge_into_location, effective_on)
    centers = LocationLink.all_children(merge_location, effective_on)
    centers.each do |center|
      LocationLink.assign(center, merge_into_location, effective_on)
    end
  end

  def all_loan_product_merge(merge_location, merge_into_location, effective_on, performed_by, recorded_by)
    loan_products = merge_location.lending_products
    loan_products.each do |loan_product|
      loan_product.lending_product_locations.first_or_create(:biz_location_id => merge_into_location.id, :effective_on => effective_on, :performed_by => performed_by, :recorded_by => recorded_by )
    end
  end

  def all_staff_member_merge(merge_location, merge_into_location, effective_on, performed_by, recorded_by)
    staff_postings = StaffPosting.get_staff_assigned(merge_location.id, effective_on)
    staff_postings.each do |staff_posting|
      StaffPosting.assign(staff_posting.staff_assigned, merge_into_location, effective_on, performed_by, recorded_by)
    end
  end

  def all_accouting_merge(merge_location, merge_into_location, effective_on, performed_by, recorded_by)
    account_locations = merge_location.accounting_locations
    account_locations.each do |account_location|
      AccountingLocation.first_or_create(:biz_location_id => merge_into_location.id, :product_type => account_location.product_type, :product_id => account_location.product_id, :cost_center => merge_into_location.cost_center, :effective_on => effective_on, :performed_by => performed_by, :recorded_by => recorded_by)
    end
    self.update(:status => COMPLETED, :completed_time => DateTime.now)
  end

  def get_location_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user)
  end

end