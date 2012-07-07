class Checklist
  include DataMapper::Resource

  property :id, Serial
  property :name, Text,:nullable=>false

  property :created_at, DateTime,:nullable=>false,:default=>Date.today
  property :deleted_at, DateTime



  has n, :sections
  has n, :responses

  belongs_to :checklist_type


end
