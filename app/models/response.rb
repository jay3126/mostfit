class Response
  include DataMapper::Resource
  
  RESPONSE_STATUSES = [:received, :success, :errors]

  property :id, Serial
  property :created_at, DateTime
  property :status, Enum.send('[]', *RESPONSE_STATUSES)
  
  belongs_to :request

end
