class LoanUtilizationValue
  include DataMapper::Resource
  
  property :id, Serial
  property :name, Text

  def self.generate_seed_data
    LoanUtilizationValue.create!(:name=>"Business")
    LoanUtilizationValue.create!(:name=>"Personal")
    LoanUtilizationValue.create!(:name=>"Education purpose")
    LoanUtilizationValue.create!(:name=>"Husband business")
    LoanUtilizationValue.create!(:name=>"Son business")
    LoanUtilizationValue.create!(:name=>"daughter business")
  end


end
