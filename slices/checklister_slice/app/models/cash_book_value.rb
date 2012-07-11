class CashBookValue
  include DataMapper::Resource

  property :id, Serial
  property :name, Text
  property :marks, Integer

  def self.generate_seed_data
        CashBookValue.create!(:name=>"Cash book/petty cash book maintenance is very good with all enteries posted and proper authentication obtained ",:marks=>3)
        CashBookValue.create!(:name=>"Cash book/petty cash book maintenance is Ok but needs few corrections and improvements ",:marks=>2)
        CashBookValue.create!(:name=>"Cash book/petty cash book maintenance is Not Ok and needs lot of correction and improvement 	",:marks=>1)


  end


end
