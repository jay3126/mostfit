class Response
  include DataMapper::Resource

  #TODO: the place should be an id corresponding to master in the database

  property :id, Serial
  property :created_at, DateTime ,:nullable=>false,:default=>Date.today
  property :deleted_at, DateTime
  property :value_date, DateTime ,:nullable=>false,:default=>Date.today

  belongs_to :target_entity
  belongs_to :filler
  belongs_to :checklist


  has n, :checkpoint_fillings
  has n, :free_text_fillings
  has n, :checklist_locations




end
