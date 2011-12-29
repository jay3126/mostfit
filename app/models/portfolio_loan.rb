class PortfolioLoan
  include DataMapper::Resource

  property :id,             Serial
  property :loan_id,        Integer, :index => true, :nullable => false, :unique => [:portfolio_id]
  property :portfolio_id,   Integer, :index => true, :nullable => false

  property :added_on,       Date, :index => true, :default => Date.today, :nullable => false
  property :active,         Boolean, :index => true, :default => true, :nullable => false

  belongs_to :portfolio
  belongs_to :loan

end
