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
    "Daily Repayment Report"
  end

  def generate
    loan_receipts = @paginate.blank? ? LoanReceipt.all(:is_advance_adjusted => false, :effective_on => @date).paginate(:page => @page, :per_page => @limit) :  LoanReceipt.all(:is_advance_adjusted => false, :effective_on => @date)
    data = {}
    data[:repayments] = @paginate.blank? ? LoanReceipt.all(:is_advance_adjusted => false, :effective_on => @date).aggregate(:id).paginate(:page => @page, :per_page => @limit) : LoanReceipt.all(:is_advance_adjusted => false, :effective_on => @date).aggregate(:id)
    data[:loan_payments] = {}
    loan_receipts.group_by{|r| r.accounted_at}.each do |branch_id, receipts|
      data[:loan_payments][branch_id] = {}
      receipts.group_by{|l| l.lending_id}.each do |lending_id, l_receipts|
        data[:loan_payments][branch_id][lending_id] = {}
        loan = Lending.get(lending_id)
        l_receipt = LoanReceipt.add_up(l_receipts)
        loan_lan = loan.lan
        branch_name = BizLocation.get(loan.accounted_at_origin).name
        center_name = BizLocation.get(loan.administered_at_origin).name
        if l_receipt[:advance_received] > MoneyManager.default_zero_money
          schedules = BaseScheduleLineItem.all('loan_base_schedule.lending_id' => lending_id, :installment.not => 0, :on_date.gte => @on_date, :order => [:on_date.desc])
          total_received = l_receipt[:principal_received] + l_receipt[:interest_received] + l_receipt[:advance_received]
          schedules.each do |schedule|
            s_principal = MoneyManager.get_money_instance_least_terms(schedule.scheduled_principal_due.to_i)
            s_interest = MoneyManager.get_money_instance_least_terms(schedule.scheduled_interest_due.to_i)

            i_received = total_received > s_interest ? total_received - s_interest : s_interest - total_received
            total_received = total_received - i_received

            p_received = total_received > s_principal ? total_received - s_principal : s_principal - total_received
            total_received = s_principal > p_received ? MoneyManager.default_zero_money : total_received - p_received
            data[:loan_payments][branch_id][lending_id][schedule.on_date] = {:schedule_date => schedule.on_date, :loan_id => lending_id, :lan_no => loan_lan, :branch_id => branch_id, :branch_name => branch_name, :center_name => center_name, :principal_received => p_received, :interest_received => i_received}
            break if total_received == MoneyManager.default_zero_money
          end

        else
          schedules = BaseScheduleLineItem.all('loan_base_schedule.lending_id' => lending_id, :installment.not => 0, :order => [:on_date])
          receipts_till_date = loan.loan_receipts(:is_advance_adjusted => false, :effective_on.lt => @date)
          received_amt_till_date = LoanReceipt.add_up(receipts_till_date)
          schedules.each do |schedule|
            s_principal = MoneyManager.get_money_instance_least_terms(schedule.scheduled_principal_due.to_i)
            s_interest = MoneyManager.get_money_instance_least_terms(schedule.scheduled_interest_due.to_i)

            r_principal = received_amt_till_date[:principal_received]
            r_interest = received_amt_till_date[:interest_received]
            received_amt_till_date[:principal_received] = received_amt_till_date[:principal_received] - s_principal if received_amt_till_date[:principal_received] > s_principal
            received_amt_till_date[:interest_received] =  received_amt_till_date[:interest_received] - s_interest if received_amt_till_date[:interest_received] > s_interest

            if(s_principal > r_principal || s_interest > r_interest)
              data[:loan_payments][branch_id][lending_id][schedule.on_date] = {}

              aj_principal = received_amt_till_date[:principal_received] != MoneyManager.default_zero_money ? s_principal - received_amt_till_date[:principal_received] : MoneyManager.default_zero_money
              aj_interest = received_amt_till_date[:interest_received] != MoneyManager.default_zero_money ? s_interest - received_amt_till_date[:interest_received] : MoneyManager.default_zero_money
              if aj_principal == MoneyManager.default_zero_money
                p_received = l_receipt[:principal_received] > s_principal ? s_principal : s_principal - l_receipt[:principal_received]
                l_receipt[:principal_received] = l_receipt[:principal_received] > s_principal ? l_receipt[:principal_received] - s_principal : MoneyManager.default_zero_money
              else
                l_receipt[:principal_received] = l_receipt[:principal_received] > aj_principal ? l_receipt[:principal_received] - aj_principal : MoneyManager.default_zero_money
                p_received = aj_principal
                received_amt_till_date[:principal_received] = MoneyManager.default_zero_money
              end

              if aj_interest == MoneyManager.default_zero_money
                i_received = l_receipt[:interest_received] > s_interest ? s_interest : s_interest - l_receipt[:interest_received]
                l_receipt[:interest_received] = l_receipt[:interest_received] > s_interest ? l_receipt[:interest_received] - s_interest : MoneyManager.default_zero_money
              else
                l_receipt[:interest_received] = l_receipt[:interest_received] > aj_interest ? l_receipt[:interest_received] - aj_interest : MoneyManager.default_zero_money
                i_received = aj_interest
                received_amt_till_date[:interest_received] = MoneyManager.default_zero_money
              end

              data[:loan_payments][branch_id][lending_id][schedule.on_date] = {:schedule_date => schedule.on_date, :loan_id => lending_id, :lan_no => loan_lan, :branch_id => branch_id, :branch_name => branch_name, :center_name => center_name, :principal_received => p_received, :interest_received => i_received}

              break if l_receipt[:principal_received] == MoneyManager.default_zero_money && l_receipt[:interest_received] == MoneyManager.default_zero_money
            end
          end
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
    csv_loan_file = File.join(folder, "repayment_detail_report_(#{@to_date.to_s}).csv")
    File.new(csv_loan_file, "w").close
    append_to_file_as_csv(headers, csv_loan_file)
    data[:loan_payments].each do |location_id, b_values|
      b_values.each do |loan_id, l_values|
        l_values.each do |on_date, s_value|
          value = [s_value[:branch_name], s_value[:center_name], s_value[:member_name], s_value[:lan_no], s_value[:schedule_date], s_value[:principal_received], s_value[:interest_received],s_value[:principal_received]+s_value[:interest_received]]
          append_to_file_as_csv([value], csv_loan_file)
        end
      end
    end
    File.new(csv_loan_file, "w").close
    return true
  end

  def append_to_file_as_csv(data, filename)
    FasterCSV.open(filename, "a", {:col_sep => "|"}) do |csv|
      data.each do |datum|
        csv << datum
      end
    end
  end

  def headers
    _headers ||= [["Branch Name", "Center Name", "Loan Account Number", "Schedule Date", "Principal", "Interest", "Amount"]]
  end

end