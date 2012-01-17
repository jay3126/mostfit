class Portfolio
  include DataMapper::Resource
  include DateParser

  before :destroy, :verified_cannot_be_deleted
  before :valid?,  :parse_dates
  
  property :id, Serial
  property :name, String, :index => true, :nullable => false, :length => 3..20
  property :start_value, Float, :nullable => true
  property :verified_by_user_id,            Integer, :nullable => true, :index => true
  property :created_by_user_id,  Integer, :nullable => false, :index => true

  property :is_securitisable, Boolean # if true, then loans in this portfolio may not already be in any other portfolio
  property :is_securitised,   Boolean
  property :params, Yaml, :length => 2000 


  property :created_at, DateTime, :default => Time.now
  property :updated_at, DateTime, :default => Time.now

  has n, :portfolio_loans
  has n, :loans, :through => :portfolio_loans
  belongs_to :created_by,  :child_key => [:created_by_user_id],   :model => 'User'

  validates_is_unique :name
  belongs_to :verified_by, :child_key => [:verified_by_user_id], :model => 'User'
  validates_with_method :verified_by_user_id, :method => :verified_cannot_be_deleted, :when => [:destroy]

  
  def take_cashflow_snapshot(every, what) # no other way to name the args.
    # @params 
    # i.e. 15, :month            => 15th of every month
    # i.e. 2, :friday            => every 2nd friday
    

    # having portfolio cashflow caches for different periods presents a unique problem. Each of the caches may have been generated at different times
    # and so be out of sync with each other. i.e. one months cache created a time t0 and for another at time t1. So, when we display monthly cashflows
    # the cashflow will not be consistent
    # therefore, portfolio caches for a particular portfolio must always be generated in a "snapshot" fashion. is this slow? fuck yeah!
    # do we have an option? fucked if I can see one....

    # also, we cannot allow the user to choose the start and end dates. we have to delete all caches that conform to this periodicity
    t = Time.now
    # voila, a datevector reflecting the dates of the cashflow
    # obviously at some point the datevector is going to have to support holiday calendars and business day adjustments, but all that can come later.


    # you know how we always wanted a function called "map_with_index"? well, if all you want to do is access the next/previous element, the below
    # is an example of how to do that elegantly

    # here we go over the various dates and create portfolios for each of them
    dates = cashflow_dates(every, what)
    model_name = "PortfolioCashflow_#{every}_#{what}"
    d1 = dates[0]
    portfolios = dates[1..-1].map do |d2|
      loan_ids = portfolio_loans(:added_on.lte => d2).aggregate(:loan_id) # loans added before the end of this period only are to be counted
      unless loan_ids.blank?
        hash = {:loan_id => loan_ids}
        balances = LoanHistory.latest_sum(hash,d2, [], Cacher::COLS)
        pmts = LoanHistory.composite_key_sum(LoanHistory.get_composite_keys(hash.merge(:date => ((d1 + 1)..d2))), [], Cacher::FLOW_COLS)    
        pc = PortfolioCache.first_or_new({:model_name => model_name, :model_id => id, :date => d1, :end_date => d2, :branch_id => 0, :center_id => 0})
        pc.attributes = (pmts[:no_group] || pmts[[]]).merge(balances[:no_group]) # if there is only one loan, there is no :no_group key in the return value. smell a bug in loan_history?
        pc.save
        puts "Done in #{Time.now - t} secs"
        pc
      else
        nil
      end
      d1 = d2 + 1 # i.e. round one is 1 - 31 jan, then 1 feb - 28 feb....so we have to bump d2 by 1
    end

  end

  def securitise(user)
    debugger
    loan_ids = self.loans.aggregate(:id)
    _id = self.id
    t0 = DateTime.now
    Portfolio.transaction do |t|
      audit_trails = loan_ids.map{|x| 
        {:auditable_id => x, :auditable_type => "Loan", :action => 2,
          :changes => {:loan_pool_id => [0,id]}.to_yaml, :created_at => t0,
          :type => 1, :user_id => user.id}
      }
      repository.adapter.execute("update loans set loan_pool_id = #{_id} where id in (#{loan_ids.join(',')})")
      repository.adapter.execute("update loan_history set loan_pool_id = #{_id} where loan_id in (#{loan_ids.join(',')})")
      sql = get_bulk_insert_sql("audit_trail", audit_trails)
      loan_pool = LoanPool.new(:name => self.name, :id => self.id)
      loan_pool.save
      repository.adapter.execute(sql)
      self.is_securitised = true
      self.save
    end
    return true

  end

  def cashflow(every, what)
    debugger
    cf = PortfolioCache.all(:model_id => self.id, :model_name => "PortfolioCashflow_#{every}_#{what}", :order => [:date])
    if cf.empty?
      self.take_cashflow_snapshot(every, what)
      cf = PortfolioCache.all(:model_id => self.id, :model_name => "PortfolioCashflow_#{every}_#{what}", :order => [:date])
    end
    return cf
  end

  def verified_cannot_be_deleted
    return true unless verified_by_user_id
    throw :halt
  end

  private 
  def cashflow_dates(every, what)
    debugger
    # return a list of dates relevant for a particular periodicity, start and end date for a cashflow
    if what == :month  # day of month
      what = :day;    of_every = 1;          period = :month
    else               # day of week
      every = 1;       of_every = every;      period = :week
    end

    loan_ids = loans.aggregate(:id)
    start_date = LoanHistory.all(:loan_id => loan_ids).aggregate(:date.min) # first loan history date for these loans
    end_date = LoanHistory.all(:loan_id => loan_ids).aggregate(:date.max) # last loan history date for these loans

    dates = ([start_date] + DateVector.new(every, what, 1, period, start_date, end_date).get_dates + [end_date]).uniq

  end

end
