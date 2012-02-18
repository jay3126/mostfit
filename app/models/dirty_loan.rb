class DirtyLoan
  include DataMapper::Resource
  @@poke_thread = false

  property :id, Serial
  property :loan_id, Integer, :index => true, :nullable => false
  property :created_at, DateTime, :index => true, :nullable => false, :default => Time.now
  property :cleaning_started, DateTime, :index => true, :nullable => true
  property :cleaned_at, DateTime, :index => true, :nullable => true

  belongs_to :loan

  def self.add(loan)
    false
  end

  def self.clear(id=nil)
  end

  def self.pending(hash = {})
    []
  end

  def self.start_thread
  end
end
