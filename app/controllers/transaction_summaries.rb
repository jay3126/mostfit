class TransactionSummaries < Application
  # provides :xml, :yaml, :js

  def index
    if params['for_date']
      #list all transaction summaries for a specified branch on a specified date
      @for_date = nil
      begin
        @for_date = Date.parse(params['for_date'])
        @for_branch_id = params['for_branch_id'].to_i
      rescue Exception => e
        raise "A date or branch was not specified"
      end
      @transaction_summaries = TransactionSummary.find_on_date_for_branch(@for_date, @for_branch_id)
      @for_branch_name = Branch.get(@for_branch_id).name if (@for_branch_id > 0) # 0 is for all branches 
    else
      @for_date = Date.today
      @transaction_summaries = TransactionSummary.find_on_date_for_branch(@for_date) 
    end
    display @transaction_summaries, :layout => layout?
  end

  def show(id)
    @transaction_summary = TransactionSummary.get(id)
    raise NotFound unless @transaction_summary
    display @transaction_summary
  end

  def new
    only_provides :html
    @transaction_summary = TransactionSummary.new
    display @transaction_summary
  end

  def edit(id)
    only_provides :html
    @transaction_summary = TransactionSummary.get(id)
    raise NotFound unless @transaction_summary
    display @transaction_summary
  end

  def create(transaction_summary)
    @transaction_summary = TransactionSummary.new(transaction_summary)
    if @transaction_summary.save
      redirect resource(@transaction_summary), :message => {:notice => "TransactionSummary was successfully created"}
    else
      message[:error] = "TransactionSummary failed to be created"
      render :new
    end
  end

  def update(id, transaction_summary)
    @transaction_summary = TransactionSummary.get(id)
    raise NotFound unless @transaction_summary
    if @transaction_summary.update(transaction_summary)
       redirect resource(@transaction_summary)
    else
      display @transaction_summary, :edit
    end
  end

  def destroy(id)
    @transaction_summary = TransactionSummary.get(id)
    raise NotFound unless @transaction_summary
    if @transaction_summary.destroy
      redirect resource(:transaction_summaries)
    else
      raise InternalServerError
    end
  end

end # TransactionSummaries
