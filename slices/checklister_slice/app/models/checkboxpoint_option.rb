class CheckboxpointOption
  include DataMapper::Resource

  property :id, Serial
  property :name, Text ,:nullable=>false
  property :sequence_number, Integer,:nullable=>false

  property :created_at, DateTime,:nullable=>false,:default=>Date.today
  property :deleted_at, DateTime


  belongs_to :checkboxpoint
  has n, :checkboxpoint_option_fillings


end
