class FreeTextFilling
  include DataMapper::Resource
  
  property :id, Serial
  property :free_text_id, Integer
  property :comment, Text
  property :response_id, Integer



end
