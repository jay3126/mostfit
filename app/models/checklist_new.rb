class ChecklistNew
  include DataMapper::Resource
  
  property :id, Serial
  property :branch_open, String

end
