class RegisterMaintanenceValue
  include DataMapper::Resource
  
  property :id, Serial
  property :name, Text
  property :marks,Integer


  def self.generate_seed_data
    RegisterMaintanenceValue.create!(:name=>"Register maintained and daily entries are regularly updated in the register ",:marks=>4)
    RegisterMaintanenceValue.create!(:name=>"Register maintained but entries are not regularly updated on a daily basis. Few enteries are made in the register at some long intervals ",:marks=>3)
    RegisterMaintanenceValue.create!(:name=>"Register is maintained but no entries are made in it ",:marks=>2)
    RegisterMaintanenceValue.create!(:name=>"Register is not maintained at all ",:marks=>1)
  end



end
