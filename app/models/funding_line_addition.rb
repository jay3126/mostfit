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

  def self.get_funder_loan_ids_by_sql(funder_id, on_date = Date.today, status = nil)
    loan_search                  = {}
    loan_ids                     = repository(:default).adapter.query("select a.lending_id from funding_line_additions a inner join (select lending_id, max(id) max_id from funding_line_additions where created_on <= '#{on_date.strftime('%Y-%m-%d')}' group by lending_id ) as b on a.id = b.max_id where a.funder_id = #{funder_id};")
    if loan_ids.blank?
      []
    else
      if status.blank?
        loan_search[:id] = loan_ids
      else
        loan_search[:status] = status
        status_key = LoanLifeCycle::LOAN_STATUSES.index(status.to_sym)
        loan_search[:id] = loan_ids.blank? || status_key.blank? ? [] : repository(:default).adapter.query("select lending_id from (select * from loan_status_changes where lending_id IN (#{loan_ids.join(',')})) s1 where s1.to_status = #{status_key+1} AND s1.to_status = (select to_status from loan_status_changes s2 where s2.lending_id = s1.lending_id AND (s2.effective_on >= '#{on_date.strftime('%Y-%m-%d')}' OR s2.effective_on <= '#{on_date.strftime('%Y-%m-%d')}') ORDER BY s2.effective_on desc LIMIT 1);")
      end
      loan_ids.blank? || loan_search[:id].blank? ? [] : loan_search[:id]
    end
  end

  def self.save_funder_id
    all(:fields => [:id, :funding_line_id]).each do |f|
      f.update(:funder_id => f.new_funding_line.new_funder_id)
    end
  end

end