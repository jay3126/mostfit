class FreeText
  include DataMapper::Resource
  
  property :id, Serial
  property :name, Text,:nullable=>false
  property :sequence_number, Integer  ,:nullable=>false

  property :created_at,            DateTime,:nullable=>false,:default=>Date.today
  property :deleted_at,            DateTime


  has n, :free_text_fillings

  belongs_to :section


end
