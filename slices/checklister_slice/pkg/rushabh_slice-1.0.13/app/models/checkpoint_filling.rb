class CheckpointFilling
  include DataMapper::Resource
  
  property :id, Serial
  property :checkpoint_id, Integer
  property :status, Boolean


end
