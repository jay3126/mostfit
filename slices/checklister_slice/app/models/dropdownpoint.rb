class Dropdownpoint
  include DataMapper::Resource


  property :id, Serial
  property :name, Text,:nullable=>false
  property :model_name, String,:nullable=>false
  property :sequence_number, Integer,:nullable=>false

  property :created_at, DateTime,:nullable=>false,:default=>Date.today
  property :deleted_at, DateTime


  belongs_to :section
  has n, :dropdownpoint_fillings




end
