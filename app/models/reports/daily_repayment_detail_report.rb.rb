class DailyRepaymentDetailReport < Report
  attr_accessor :date, :file_format

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
    "Daily Repayment Detail Report"
  end

  def generate
    loan_receipts = @paginate.blank? ? LoanReceipt.all(:is_advance_adjusted => false, :effective_on => @date).paginate(:page => @page, :per_page => @limit) :  LoanReceipt.all(:is_advance_adjusted => false, :effective_on => @date)
    data = {}
    data[:repayments] = @paginate.blank? ? LoanReceipt.all(:is_advance_adjusted => false, :effective_on => @date).aggregate(:id).paginate(:page => @page, :per_page => @limit) : LoanReceipt.all(:is_advance_adjusted => false, :effective_on => @date).aggregate(:id)
    data[:loan_payments] = {}
    loan_receipts.group_by{|r| r.accounted_at}.each do |branch_id, receipts|
      branch_name = BizLocation.get(branch_id).name
      data[:loan_payments][branch_id] = {}
      receipts.group_by{|l| l.lending_id}.each do |lending_id, l_receipts|
        data[:loan_payments][branch_id][lending_id] = {}
        loan = Lending.get(lending_id)
        loan_lan = loan.lan
        center_name = BizLocation.get(loan.administered_at_origin).name
        l_receipts.each do |l_receipt|
          data[:loan_payments][branch_id][lending_id][l_receipt.effective_on] = {:schedule_date => l_receipt.effective_on, :loan_id => lending_id, :lan_no => loan_lan, :branch_id => branch_id, :branch_name => branch_name, :center_name => center_name, :principal_received => l_receipt.to_money[:principal_received], :interest_received => l_receipt.to_money[:interest_received], :advance_received => l_receipt.to_money[:advance_received], :recovery_reveived => l_receipt.to_money[:loan_recovery]}
        end
      end
    end
    data
  end
  
  def generate_xls
    @paginate = true
    data = generate

    folder = File.join(Merb.root, "doc", "xls", "company",'reports', self.class.name.split(' ').join().downcase)
    FileUtils.mkdir_p(folder)
    csv_loan_file = File.join(folder, "daily_repayment_detail_report_(#{@date.to_s}).csv")
    File.new(csv_loan_file, "w").close
    append_to_file_as_csv(headers, csv_loan_file)
    data[:loan_payments].each do |location_id, b_values|
      b_values.each do |loan_id, l_values|
        l_values.each do |on_date, s_value|
          value = [s_value[:branch_name], s_value[:center_name], s_value[:lan_no], s_value[:schedule_date], s_value[:principal_received], s_value[:interest_received],s_value[:advance_received],s_value[:recovery_reveived]]
          append_to_file_as_csv([value], csv_loan_file)
        end
      end
    end
    return true
  end

  def append_to_file_as_csv(data, filename)
    FasterCSV.open(filename, "a", {:col_sep => ","}) do |csv|
      data.each do |datum|
        csv << datum
      end
    end
  end

  def headers
    _headers ||= [["Branch Name", "Center Name", "Loan Account Number", "Schedule Date", "Principal", "Interest", "Advance", "Recovery"]]
  end

end