class DailyRepaymentDetailReport < Report
  attr_accessor :date

  def initialize(params, date, user)
    @date = date.blank? ? Date.today : date[:date]
    @name = "Report on #{@date}"
    @page = params.blank? || params[:page].blank? ? 1 :params[:page]
    @limit = 100
    get_parameters(params, user)
  end

  def name
    "Daily Repayment Detail Report on #{@date}"
  end

  def self.name
    "Daily Repayment Report"
  end

  def generate
    loan_receipts = LoanReceipt.all(:effective_on => @date).paginate(:page => @page, :per_page => @limit)
    data = {}
    data[:repayments] = LoanReceipt.all(:effective_on => @date).aggregate(:id).paginate(:page => @page, :per_page => @limit)
    data[:loan_payments] = {}
    loan_receipts.group_by{|r| r.accounted_at}.each do |branch_id, receipts|
      data[:loan_payments][branch_id] = {}
      receipts.group_by{|l| l.lending_id}.each do |lending_id, l_receipts|
        loan = Lending.get(lending_id)
        l_receipt = LoanReceipt.add_up(l_receipts)
        loan_lan = loan.lan
        branch_name = BizLocation.get(loan.accounted_at_origin).name
        center_name = BizLocation.get(loan.administered_at_origin).name
        schedule = BaseScheduleLineItem.last('loan_base_schedule.lending_id' => lending_id, :on_date.lte => @date)
        schedule_date = schedule.blank? ? loan.scheduled_first_repayment_date : schedule.on_date

        data[:loan_payments][branch_id][lending_id] = {:schedule_date => schedule_date, :loan_id => lending_id, :lan_no => loan_lan, :branch_id => branch_id, :branch_name => branch_name, :center_name => center_name, :principal_received => l_receipt[:principal_received], :interest_received => l_receipt[:interest_received], :advance_received => l_receipt[:advance_received]}
      end
    end
    data
  end

end