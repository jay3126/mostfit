class ChecklistLocation
  include DataMapper::Resource
  
  property :id, Serial
  property :location_id, Integer
  property :type, String
  property :name, String
  property :created_at, DateTime,:nullable=>false,:default=>Date.today
  property :deleted_at, DateTime


  belongs_to :response

end
