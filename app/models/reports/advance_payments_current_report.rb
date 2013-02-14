class AdvancePaymentsCurrentReport < Report
  attr_accessor :date, :file_format

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Advance Payment Current Report on #{@date}"
    @user = user
    @page = params.blank? || params[:page].blank? ? 1 :params[:page]
    @limit = 500
    get_parameters(params, user)
  end

  def name
    "Advance Payments Current Report on #{@date}"
  end

  def self.name
    "Advance Payments Current Report"
  end
  def managed_by_staff(location_id, on_date)
    location_facade = get_location_facade(@user)
    location_manage = location_facade.location_managed_by_staff(location_id, on_date)
    if location_manage.blank?
      'Not Managed'
    else
      location_manage.manager_staff_member.name
    end
  end
  def get_reporting_facade(user)
    @reporting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, user)
  end

  def get_location_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user)
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate

    data = {}
    advance_loans_ids = @paginate.blank? ? Lending.all_advance_avaiable_loans_for_location(@date).paginate(:page => @page, :per_page => @limit) : Lending.all_advance_avaiable_loans_for_location(@date)
    advance_loans = advance_loans_ids.blank? ? [] : Lending.all(:id => advance_loans_ids, :fields => [:id, :lan, :administered_at_origin, :accounted_at_origin])
    data[:loan_record] = advance_loans_ids
    data[:records] = {}
    advance_loans.each do |loan|
      member                    = loan.loan_borrower.counterparty
      if member.blank?
        member_id = ''
        member_name = 'Not Specified'
      else
        member_id       = member.id
        member_name     = member.name
      end
      loan_id                    = loan.id
      loan_account_number        = loan.lan
      advance_payment            = loan.advance_balance(@date)
      center                     = loan.administered_at_origin_location
      center_id                  = center ? center.id : "Not Specified"
      center_name                = center ? center.name : "Not Specified"
      branch                     = loan.accounted_at_origin_location
      branch_name                = branch ? branch.name : "Not Specified"
      branch_id                  = branch ? branch.id : "Not Specified"
      fco_name                   = center.blank? ? "Not Specified" : managed_by_staff(center.id, @date)

      data[:records][loan.id] = {:member_name => member_name, :member_id => member_id,
        :center_name => center_name, :center_id => center_id, :loan_account_number => loan_account_number,
        :branch_name => branch_name, :branch_id => branch_id,
        :loan_id => loan_id, :fco_name => fco_name, :advance_payment => advance_payment}
    end
    data
  end
  def generate_xls
    @paginate = true
    data = generate

    folder = File.join(Merb.root, "doc", "xls", "company",'reports', self.class.name.split(' ').join().downcase)
    FileUtils.mkdir_p(folder)
    csv_loan_file = File.join(folder, "advance_payments_current_report_all_branches_#{@date.to_s}.csv")
    File.new(csv_loan_file, "w").close
    append_to_file_as_csv(headers, csv_loan_file)
    data[:records].each do |loan_id, s_value|
      value = [s_value[:branch_name], s_value[:center_name], s_value[:fco_name], s_value[:loan_account_number], s_value[:par], [:member_name],[:advance_payment]]
      append_to_file_as_csv([value], csv_loan_file)
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
    _headers ||= [['Branch Name', 'Center Name', 'FCO Name', 'Loan Account Number', 'Customer Name', 'Advance Payment']]
  end
end
