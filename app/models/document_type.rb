class DocumentType
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, :length => 100
  property :parent_models, String, :length => 200
  
  has n, :documents
  validates_is_unique :name
  
  default_scope(:default).update(:order => [:name])
end
