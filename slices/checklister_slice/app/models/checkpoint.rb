class Checkpoint
  include DataMapper::Resource

  property :id, Serial
  property :name, Text ,:nullable=>false
  property :sequence_number, Integer,:nullable=>false

  property :created_at, DateTime,:nullable=>false,:default=>Date.today
  property :deleted_at, DateTime


  belongs_to :section
  has n, :checkpoint_fillings


  def generate_data

  end

end
