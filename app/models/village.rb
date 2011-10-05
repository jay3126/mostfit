class Village
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, :length => 60
  belongs_to :area

  validates_is_unique :name, :scope => [:area]
  validates_length :name, :min => 4
end
