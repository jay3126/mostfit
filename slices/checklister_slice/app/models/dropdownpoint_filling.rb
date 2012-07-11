class DropdownpointFilling
  include DataMapper::Resource

  property :id, Serial
  property :model_record_id, Integer, :nullable => false
  property :model_record_name, Text, :nullable => false

  property :created_at, DateTime,:nullable=>false,:default=>Date.today
  property :deleted_at, DateTime


  belongs_to :dropdownpoint
  belongs_to :response


end
