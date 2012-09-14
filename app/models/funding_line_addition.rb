class FundingLineAddition
  include DataMapper::Resource

  property :id,                  Serial
  property :lending_id,          Integer,  :nullable => false
  property :funding_line_id,     Integer,  :nullable => false
  property :tranch_id,           Integer,  :nullable => false
  property :created_by_staff,    Integer,  :nullable => false
  property :created_on,          Date,     :nullable => false
  property :created_by_user,     Integer,  :nullable => false
  property :created_at,          DateTime, :nullable => false, :default => DateTime.now

  def self.assign_tranch_to_loan(lending_id, funding_line_id, tranch_id, created_by_staff, created_on, created_by_user)
    funding_line_addition = {}
    funding_line_addition[:lending_id] = lending_id
    funding_line_addition[:funding_line_id] = funding_line_id
    funding_line_addition[:tranch_id] = tranch_id
    funding_line_addition[:created_by_staff] = created_by_staff
    funding_line_addition[:lending_id] = lending_id
    funding_line_addition[:created_on] = created_on
    funding_line_addition[:created_by_user] = created_by_user
    assign_tranch = create(funding_line_addition)
    raise Errors::DataError, assign_tranch.errors.first.first unless assign_tranch.saved?
    assign_tranch
  end

end