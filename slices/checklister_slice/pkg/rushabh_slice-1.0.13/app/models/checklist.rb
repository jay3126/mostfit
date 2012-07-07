class Checklist
  include DataMapper::Resource
  
  property :id, Serial
  property :checklist_type_id, Integer
  property :name, String


end
