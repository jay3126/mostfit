class JournalBook < Report

  attr_accessor :from_date, :to_date, :branch_id
  DATE_RANGE = 3

  def initialize(params, dates, user)
    @to_date = (dates and dates[:to_date] and not (dates[:to_date] == "")) ? dates[:to_date] : Date.today
    @from_date = (dates and dates[:from_date] and not (dates[:from_date] == "")) ? dates[:from_date] : @to_date - 7
    @branch_id = (params and params.key?(:branch_id) and not (params[:branch_id] == "")) ? params[:branch_id] : 0
    get_parameters(params, user)
  end
  
  def name
    "Journal for #{get_branch_name(@branch_id)} from #{@from_date} to #{(@to_date)}"
  end
  
  def self.name
    "Journal"
  end

  def get_branch_name(branch_id)
    return "" unless branch_id
    return "Head Office" if branch_id == 0
    branch = Branch.get(branch_id)
    branch ? branch.name : ""
  end
  
  def generate
    data = {}
    journals_by_date = {}
    @from_date.upto(@to_date) {|dt| journals_by_date[dt] = []}
    journals = Journal.all(:date.gte => @from_date, :date.lte => @to_date, :order => [:date.desc])
    journals.each do |j|
      journals_on_date = journals_by_date[j.date]
      j.postings.each do |p|
        account = p.account
        journals_on_date.push(j) if (account and (account.branch_id == @branch_id))
      end
    end
    data[:journals_by_date] = journals_by_date
    data
  end

end
