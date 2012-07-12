class Section
  include DataMapper::Resource

  property :id, Serial
  property :instructions, Text ,:nullable=>false
  property :name, Text,:nullable=>false
  property :created_at,            DateTime,:nullable=>false,:default=>Date.today
  property :deleted_at,            DateTime
  property :has_score,Boolean,:default=>false,:nullable=>false



  belongs_to :section_type
  belongs_to :checklist

  has n, :free_texts
  has n, :checkpoints
  has n, :dropdownpoints
  has n, :checkboxpoints


end
