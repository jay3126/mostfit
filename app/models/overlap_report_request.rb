class OverlapReportRequest
  include DataMapper::Resource
  include Constants::Status

  property :id,     Serial
  property :status, Enum.send('[]', *REQUEST_STATUSES), :nullable => false, :default => CREATED_STATUS

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

end
