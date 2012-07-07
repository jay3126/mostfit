class FreeText
  include DataMapper::Resource
  
  property :id, Serial
  property :section_id, Integer
  property :name, String


end
