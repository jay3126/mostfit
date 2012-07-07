class CheckboxpointOptionFilling
  include DataMapper::Resource

  property :id, Serial
  property :status,Boolean
  property :created_at, DateTime,:nullable=>false,:default=>Date.today
  property :deleted_at, DateTime


  belongs_to :response
 belongs_to :checkboxpoint_option


end
