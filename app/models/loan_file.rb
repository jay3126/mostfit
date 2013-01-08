class LoanFileInfo

  attr_reader :id, :loan_file_identifier, :at_branch_id, :at_center_id, :for_cycle_number, :scheduled_disbursal_date, :scheduled_first_payment_date, :created_by_staff_id, :created_on, :created_by, :created_at, :loan_applications

  def initialize(id, loan_file_identifier, at_branch_id, at_center_id, for_cycle_number, scheduled_disbursal_date, scheduled_first_payment_date, created_by_staff_id, created_on, created_by, created_at, loan_applications = [])
    @id = id
    @loan_file_identifier = loan_file_identifier
    @at_branch_id = at_branch_id
    @at_center_id = at_center_id
    @for_cycle_number = for_cycle_number
    @scheduled_disbursal_date = scheduled_disbursal_date
    @scheduled_first_payment_date = scheduled_first_payment_date
    @created_by_staff_id = created_by_staff_id
    @created_on = created_on
    @created_by = created_by
    @created_at = created_at
    @loan_applications = loan_applications
  end

end

# A loan file lists a number of loan applications that are being processed together
class LoanFile
  include DataMapper::Resource
  include Constants::Status
  include Pdf::LoanSchedule if PDF_WRITER

  property :id,                           Serial
  property :at_branch_id,                 Integer, :nullable => false
  property :at_center_id,                 Integer, :nullable => false
  property :for_cycle_number,             Integer, :nullable => false
  property :loan_file_identifier,         String,  :nullable => false,
    :default => lambda {|obj, p| 
    branch_identifier = BizLocation.get_biz_location_identifier(obj.at_branch_id)
    center_identifier = BizLocation.get_biz_location_identifier(obj.at_center_id)
    lf_no = "%.3i"%get_loan_file_identifier
    "LF-#{branch_identifier}-#{center_identifier}-#{obj.created_on.strftime('%d%m%Y')}-#{lf_no}"}
  property :scheduled_disbursal_date,     Date, :nullable => false
  property :scheduled_first_payment_date, Date, :nullable => false
  property :created_by_staff_id,          Integer, :nullable => false
  property :created_on,                   Date, :nullable => false
  property :created_by,                   Integer, :nullable => false
  property :created_at,                   DateTime, :nullable => false, :default => DateTime.now
  property :health_check_status,          Enum.send('[]', *HEALTH_CHECK_STATUSES), :nullable => false, :default => NEW_STATUS
  property :health_status_remark,         Text, :nullable => true, :lazy => true
  property :health_check_approved_by,     Integer, :nullable => true
  property :health_check_approved_on,     DateTime, :nullable => true

  has n, :loan_file_additions
  has n, :loan_applications, :through => :loan_file_additions

  def name
    "loan_file_#{self.loan_file_identifier}"
  end

  def to_info
    loan_applications = self.loan_applications.collect{|lap| lap.to_info}
    LoanFileInfo.new(id, loan_file_identifier, at_branch_id, at_center_id, for_cycle_number, scheduled_disbursal_date, scheduled_first_payment_date, created_on, created_by_staff_id, created_by, created_at, loan_applications)
  end

  def self.search(q, per_page=10)
    all(:conditions => {:loan_file_identifier => q}, :limit => per_page)
  end
  
  def self.generate_loan_file(at_branch, at_center, for_cycle_number, scheduled_disbursal_date, scheduled_first_payment_date, by_staff, on_date, by_user)
    query_params = {}
    query_params[:at_branch_id] = at_branch
    query_params[:at_center_id] = at_center
    query_params[:for_cycle_number] = for_cycle_number
    query_params[:scheduled_disbursal_date] = scheduled_disbursal_date
    query_params[:scheduled_first_payment_date] = scheduled_first_payment_date
    query_params[:created_by_staff_id] = by_staff
    query_params[:created_on] = on_date
    query_params[:created_by] = by_user
    create(query_params)
  end

  def self.locate_loan_file(by_identifier)
    first(:loan_file_identifier => by_identifier)
  end

  def self.locate_loan_file_at_center(at_branch, at_center, for_cycle_number)
    laf = first(:at_branch_id => at_branch, :at_center_id => at_center, :for_cycle_number => for_cycle_number)
    if laf.nil?
      nil
    else
      laf.to_info
    end
  end
  
  def self.locate_loan_files_at_center_at_branch_for_cycle(at_branch, at_center, for_cycle_number)
    loan_files = all(:at_branch_id => at_branch, :at_center_id => at_center, :for_cycle_number => for_cycle_number)#.collect{ |lf| lf.to_info}
    loan_files
  end

  def self.get_loan_file_info(loan_file_identifier)
    loan_file = locate_loan_file(loan_file_identifier)
    loan_file ? loan_file.to_info : nil
  end

  # this method is now no longer in use
  #is the loan file in the state that new clients can be created for loan applications which do not have any?
  def is_ready_for_client_creation?
    return true if self.health_check_status == Constants::Status::HEALTH_CHECK_APPROVED
    return false
  end

  # this method is now no longer in use
  #creates corresponding client instances for loan applications which do not have ones.
  def create_clients
    #are we ready to create clients for this loan file ?
    return false unless self.is_ready_for_client_creation?
    return_status = {:clients_created => [], :clients_not_created => []}

    self.loan_applications.each do |loan_application|
      client = loan_application.create_client
      if client.nil?
        next
      elsif client.saved?
        return_status[:clients_created] << [loan_application.id, client.id]
      else
        return_status[:clients_not_created] << [loan_application.id, client.errors.to_a].flatten
      end
    end

    return_status
  end

  def self.get_loan_file_identifier
    LoanFile.last.blank? ? 1 : (LoanFile.last.loan_file_identifier.split("-").last).to_i + 1
  end
end