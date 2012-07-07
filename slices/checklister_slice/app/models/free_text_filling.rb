class FreeTextFilling
  include DataMapper::Resource
  
  property :id, Serial
  property :comment, Text,:nullable=>false

  property :created_at,            DateTime,:nullable=>false,:default=>Date.today
  property :deleted_at,            DateTime


  belongs_to :free_text
  belongs_to :response



end
