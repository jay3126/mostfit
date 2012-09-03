class OverlapReportRequest
  include DataMapper::Resource
  include Constants::Status

  property :id,                  Serial
  property :status,              Enum.send('[]', *REQUEST_STATUSES), :nullable => false, :default => CREATED_STATUS
  property :loan_application_id, Integer
  property :created_at,          DateTime

  # Call this method to obtain the 'local' status of a request
  def get_status
    self.status
  end

  # Set the 'local' status of a request
  # Returns true if the status was changed, else returns false
  def set_status(new_status)
    raise ArgumentError, "does not support the status: #{new_status}" unless REQUEST_STATUSES.include?(new_status)
    return false if get_status == new_status
    self.status = new_status
  end

  # Returns any requests that are pending for communication to the credit bureau
  def self.pending_credit_bureau
    all(:status => CREATED_STATUS)
  end

  # This marks the request as one that has been communicated to the credit bureau
  def mark_sent
    self.set_status(SENT_STATUS)
  end

  def self.generate_credit_bureau_request_file(branch, center)
    errors = {}
    errors[:generation_errors] = {}
    errors[:save_status_errors] = {}
    options = {:at_branch_id => branch, :at_center_id => center}
    loan_applications = LoanApplication.pending_overlap_report_request_generation(options)
    credit_bureau_name = "Highmark"
    request_name = "overlap_report_request"

    folder = File.join(Merb.root, "docs","highmark","requests")
    FileUtils.mkdir_p folder
    filename = File.join(folder, "#{credit_bureau_name}.#{request_name}.#{DateTime.now.strftime('%Y-%m-%d_%H:%M')}.csv")
    FasterCSV.open(filename, "w", {:col_sep => "|"}) do |csv|
      loan_applications.each do |loan_application|
        begin
          csv << loan_application.row_to_delimited_file
        rescue Exception => error
          errors[:generation_errors][loan_application.id] = error
        end
        loan_application.generate_credit_bureau_request
        errors[:save_status_errors][loan_application.id] = loan_application.errors unless loan_application.save or loan_application.generate_credit_bureau_request
      end
    end

    raise "There are some loan applications which are either in new status or suspected duplicate" if loan_applications.blank?

    log_folder = File.join(Merb.root, "log","highmark","requests")
    FileUtils.mkdir_p log_folder
    error_filename = File.join(log_folder, "#{credit_bureau_name}.#{request_name}.#{DateTime.now.strftime('%Y-%m-%d_%H:%M')}.csv")
    FasterCSV.open(error_filename, "w", {:col_sep => "|"}) do |csv|
      csv << ["ROW GENERATION ERROR FOR THE LOAN APPLICATIONS"]
      errors[:generation_errors].keys.each do |e|
        csv << [e, errors[:generation_errors][e]].flatten
      end
      csv << ["ERRORS SAVING THE STATUS OF THE LOAN APPLICATIONS"]
      errors[:save_status_errors].keys.each do |e|
        csv << [e, errors[:save_status_errors][e].to_a].flatten()
      end
    end

    FileUtils.rm([filename, error_filename]) if loan_applications.empty?
  end

end
