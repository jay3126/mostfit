class FundingLineAdditions
  include DataMapper::Resource

  property :id,                  Serial
  property :lending_id,          Integer,  :nullable => false
  property :funding_line_id,     Integer,  :nullable => false
  property :tranch_id,           Integer,  :nullable => false
  property :created_by_staff,    Integer,  :nullable => false
  property :created_on,          Date,     :nullable => false
  property :created_by_user,     Integer,  :nullable => false
  property :created_at,          DateTime, :nullable => false, :default => DateTime.now

  def initialize
    
  end

end
