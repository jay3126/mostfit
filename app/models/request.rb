class Request
  include DataMapper::Resource
  
  REQUEST_STATUSES = [:created, :sent, :response_received, :to_be_resent, :not_to_be_resent, :closed]

  property :id, Serial
  property :created_at, DateTime
  property :created_by_user_id, Integer

  belongs_to :created_by, :child_key => [:created_by_user_id], :model => 'User'
  
  has n, :responses

  private
  property :status, Enum.send('[]', *REQUEST_STATUSES)

  public

  # A status of an instance of the Request class can only be changed by the following function
  # This function will return true if the status change is valid? else it will return false and the status of the Request object will not have changed
  def get_status
    return status
  end

  def set_status(new_status)
    return nil
  end

end
