class CashAndCollectionReport
  include DataMapper::Resource
  
  property :id, Serial
  property :name, Text
  property :marks, Integer

  def self.generate_seed_data
    CashAndCollectionReport.create!(:name=>"Are RO's are coming back iin time after last meeting ",:marks=>4)
    CashAndCollectionReport.create!(:name=>"Cash collected and deposited in bank in time ",:marks=>3)
    CashAndCollectionReport.create!(:name=>"Pending cash kept in safe and reported properly ",:marks=>2)
    CashAndCollectionReport.create!(:name=>"Cash report send by AO ",:marks=>1)
  end


end
