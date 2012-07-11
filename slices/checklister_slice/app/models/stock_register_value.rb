class StockRegisterValue
  include DataMapper::Resource

  property :id, Serial
  property :name, Text
  property :marks, Integer

  def self.generate_seed_data
    StockRegisterValue.create!(:name => "Stock registers maintenance for Receipt book ", :marks => 4)
    StockRegisterValue.create!(:name => "Register maintained and updated regularly ", :marks => 3)
    StockRegisterValue.create!(:name => "Register maintained and not updated regularly ", :marks => 2)
    StockRegisterValue.create!(:name => "Register not maintained ", :marks => 1)
  end


end
