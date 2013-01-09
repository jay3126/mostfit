class CustomerExtractForInsurance < Report

  attr_accessor :from_date, :to_date, :page

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Customer Extract For Insurance Report from #{@from_date} to #{@to_date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch] and (not (params[:biz_location_branch].empty?))) ? params[:biz_location_branch] : all_branch_ids
    @page = params.blank? || params[:page].blank? ? 1 :params[:page]
    @limit = 10
    get_parameters(params, user)
  end

  def name
    "Customer Extract For Insurance Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Customer Extract For Insurance Report"
  end

  def get_location_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user)
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate
    data = {}
    #    params = {:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date, :accounted_at_origin => @biz_location_branch}
    loan_ids = Lending.all(:fields => [:accounted_at_origin, :administered_at_origin, :disbursal_date, :id, :lan, :applied_amount], :disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date, :accounted_at_origin => @biz_location_branch).to_a.paginate(:page => @page, :per_page => @limit)
    #    loan_ids = Lending.all(params).to_a.paginate(:page => @page, :per_page => @limit)
    data[:paginated_loan_ids] = loan_ids
    data[:loans] = {}
    loan_ids.each do |loan|
      branch = BizLocation.get(loan.accounted_at_origin)
      branch_id = branch ? branch.id : "Not Specified"
      branch_name = branch ? branch.name : "Not Specified"
      center = BizLocation.get(loan.administered_at_origin)
      center_id = center ? center.id : "Not Specified"
      center_name = center ? center.name : "Not Specified"
      loan_borrower = LoanBorrower.first(:counterparty_id => 1)
      client = loan_borrower.counterparty
      client_name = client ? client.name : "Not Specified"
      client_id = client ? client.id : "Not Specified"
      gender = (client and client.gender) ? client.gender.to_s : "Not Specified"
      date_of_birth = (client and client.date_of_birth) ? client.date_of_birth : "Not Specified"
      age_as_on_loan_disbursement_date = (loan and loan.disbursal_date and client and client.date_of_birth) ? (loan.disbursal_date.strftime("%Y").to_i - client.date_of_birth.strftime("%Y").to_i) : "Age not available"
      guarantor_name = (client and client.guarantor_name) ? client.guarantor_name : "Not Specified"
      guarantor_relationship = (client and client.guarantor_relationship) ? client.guarantor_relationship : "Not Specified"
      loan_id = loan ? loan.id : "Not Specified"
      loan_lan = (loan and loan.lan) ? loan.lan : "Not Specified"
      loan_disbursement_date = (loan and loan.disbursal_date) ? loan.disbursal_date : "Not Specified"
      loan_amount = (loan and loan.applied_amount) ? Money.new(loan.applied_amount.to_i, :INR).to_s : "Not Specified"
      loan_base_schedule = LoanBaseSchedule.first(:fields => [:first_receipt_on], :lending_id => loan.id)
      loan_commencement_date = (loan_base_schedule.blank?) ? "Not Available" : loan_base_schedule.first_receipt_on
      simple_insurance_policies = SimpleInsurancePolicy.first(:lending_id => loan.id)
      cover_amount = (simple_insurance_policies.blank?) ? "Insurance Not Specified" : simple_insurance_policies.si_money_amount.to_s
      premium = "Insurance Not Specified"
      service_tax = "Insurance Not Specified"
      total_premium = "Insurance Not Specified"

      data[:loans][loan] = {:branch_id => branch_id, :branch_name => branch_name, :center_id => center_id, :center_name => center_name, :client_id => client_id, :client_name => client_name, :gender => gender, :date_of_birth => date_of_birth, :age_as_on_loan_disbursement_date => age_as_on_loan_disbursement_date, :guarantor_name => guarantor_name, :guarantor_relationship => guarantor_relationship, :loan_id => loan_id, :loan_lan => loan_lan, :loan_disbursement_date => loan_disbursement_date, :loan_amount => loan_amount, :loan_commencement_date => loan_commencement_date, :cover_amount => cover_amount, :premium => premium, :service_tax => service_tax, :total_premium => total_premium}
    end
    data
  end
end