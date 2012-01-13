class PrioritySectorList
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String
  property :code, String, :length => 3

  validates_present   :name
  validates_is_unique :name
  validates_is_unique :code

  has n, :clients
  has n, :psl_sub_categories

  default_scope(:default).update(:order => [:name])
end
