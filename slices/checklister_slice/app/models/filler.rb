class Filler
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String ,:nullable=>false
  property :role, String,:nullable=>false
  property :type, String,:nullable=>false
  property :model_record_id, Integer,:nullable=>false

  property :created_at,            DateTime,:nullable=>false,:default=>Date.today
  property :deleted_at,            DateTime


  has n, :responses


end
