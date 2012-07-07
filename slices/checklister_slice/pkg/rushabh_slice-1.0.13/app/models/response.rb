class Response
  include DataMapper::Resource
  
  property :id, Serial
  property :filler_id, Integer
  property :checklist_id, Integer
  property :target_entity_id, Integer


end
