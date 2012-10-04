class BookKeepings < Application
  # provides :xml, :yaml, :js

  def index
    render :index
  end

  def eod_accounting
    @message         = {}
    @cost_centers    = []
    @ledgers         = []
    @date            = params[:on_date]
    cost_center_ids  = params[:cost_center_ids]
    @message[:error] = "Please Select Cost Center" if cost_center_ids.blank?
    @message[:error] = "Date cannot be blank" if @date.blank?

    if @message.blank?
      @date           = Date.parse @date
      @cost_centers   = CostCenter.all(:id => cost_center_ids) unless cost_center_ids.blank?
      @cost_centers.each{|c_center| @ledgers << c_center.get_sum_of_balances_cost_center(@date).first}
      @ledgers = @ledgers.flatten.compact.uniq
    end
    display @cost_centers
  end

  def update_accounting_status_on_date

  end

end # BookKeeping
