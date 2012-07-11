class CleanlinessCommentValue
  include DataMapper::Resource
  property :id, Serial
  property :name, Text
  property :marks,Integer

  def self.generate_seed_data
    CleanlinessCommentValue.create!(:name=>"Unnecessary items not seen at all in the branch ",:marks=>3)
    CleanlinessCommentValue.create!(:name=>"Unnecessary items partially seen in the branch ",:marks=>2)
    CleanlinessCommentValue.create!(:name=>"Unnecessary items seen all over the branch ",:marks=>1)
  end


end
