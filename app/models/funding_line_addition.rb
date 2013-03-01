class FundingLineAddition
  include DataMapper::Resource

  property :id,                  Serial
  property :lending_id,          Integer,  :nullable => false
  property :funder_id,           Integer,  :nullable => false
  property :funding_line_id,     Integer,  :nullable => false
  property :tranch_id,           Integer,  :nullable => false
  property :created_by_staff,    Integer,  :nullable => false
  property :created_on,          Date,     :nullable => false
  property :created_by_user,     Integer,  :nullable => false
  property :created_at,          DateTime, :nullable => false, :default => DateTime.now

  belongs_to :lending
  belongs_to :new_funding_line, :child_key => [:funding_line_id], :model => 'NewFundingLine'

  def self.assign_tranch_to_loan(lending_id, funding_line_id, tranch_id, created_by_staff, created_on, created_by_user)
    funding_line_addition = {}
    funding_line_addition[:lending_id] = lending_id
    funding_line_addition[:funding_line_id] = funding_line_id
    funding_line_addition[:tranch_id] = tranch_id
    funding_line_addition[:created_by_staff] = created_by_staff
    funding_line_addition[:lending_id] = lending_id
    funding_line_addition[:created_on] = created_on
    funding_line_addition[:created_by_user] = created_by_user
    funding_line_addition[:funder_id] = NewFundingLine.get(funding_line_id).new_funder_id
    assign_tranch = create(funding_line_addition)
    raise Errors::DataError, assign_tranch.errors.first.first unless assign_tranch.saved?
    assign_tranch
  end

  def self.get_funder_assigned_to_loan(lending_id)
    funding_line_addition = last(:lending_id => lending_id)
    funding_line_id = funding_line_addition.funding_line_id
    funding_line = NewFundingLine.get funding_line_id
    funding_line.new_funder
  end

  def self.get_funding_line_assigned_to_loan(lending_id)
    funding_line_addition = last(:lending_id => lending_id)
    funding_line_id = funding_line_addition.funding_line_id
    NewFundingLine.get funding_line_id
  end

  def self.get_tranch_assigned_to_loan(lending_id)
    funding_line_addition = last(:lending_id => lending_id)
    tranch_id = funding_line_addition.tranch_id
    NewTranch.get tranch_id
  end

  def self.get_funder_loan_ids_by_sql(funder_id, on_date = Date.today)
    allocation                   = {}
    allocation[:funder_id]       = funder_id
    allocation[:created_on.lte]  = on_date
    loan_ids                     = all(allocation).map(&:lending_id)
    if loan_ids.blank?
      []
    else
      l_loans = repository(:default).adapter.query("select lending_id from (select * from funding_line_additions where lending_id IN (#{loan_ids.join(',')})) la where la.funder_id = (select funder_id from (select * from funding_line_additions where lending_id IN (#{loan_ids.join(',')})) la1 where la.lending_id = la1.lending_id AND la.funder_id IN (#{funder_id}) order by la1.created_on desc limit 1 );")
      l_loans.blank? ? [] : l_loans
    end
  end

  def self.save_funder_id
    all(:fields => [:id, :funding_line_id]).each do |f|
      f.update(:funder_id => f.new_funding_line.new_funder_id)
    end
  end

end