class CheckpointFilling
  include DataMapper::Resource
  
  property :id, Serial
  property :status, Boolean,:nullable=>false

  property :created_at,            DateTime ,:nullable=>false,:default=>Date.today
  property :deleted_at,            DateTime


  belongs_to :checkpoint
  belongs_to :response

end
