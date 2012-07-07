class Section
  include DataMapper::Resource

  property :id, Serial
  property :instructions, Text
  property :name, String
  property :section_type_id, Integer
  property :checklist_id, Integer


end
