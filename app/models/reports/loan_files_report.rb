class LoanFilesReport < Report
  attr_accessor :branch, :center, :branch_for_loan_application_report, :center_for_loan_application_report, :loan_file_status, :effective_date

  def initialize(params, date, user)
    @date = date.blank? ? Date.today : date
    @name   = "Report on #{@date}"
    @loan_file_status = params[:loan_file_status].gsub(' ',"_").downcase rescue ""
    @branch_id = params[:branch_for_loan_application_report] rescue ""
    @center_id = params[:center_for_loan_application_report] rescue ""
    get_parameters(params, user)
  end

  def name
    "Loan File Report on #{@date}"
  end

  def self.name
    "Loan File Report"
  end

  def generate
    condition_hash =  {}
    loan_app = {}
    condition_hash.merge!(:health_check_status => @loan_file_status) unless @loan_file_status.blank?
    condition_hash.merge!(:at_center_id => @center_id) unless @center_id.blank?
    condition_hash.merge!(:at_branch_id => @branch_id) unless @branch_id.blank?
    loan_files = LoanFile.all(condition_hash)
    branches = BizLocation.all(:id => loan_files.map(&:at_branch_id))
    centers = BizLocation.all(:id => loan_files.map(&:at_center_id))
    loan_files.group_by{|x| [x.at_branch_id,x.at_center_id,x.health_check_status]}.collect{|c| loan_app.merge!(branches.find{|x| x.id == c[0][0]}.id => { centers.find{|x| x.id == c[0][1]}.id => { c[0][2] => c[1].count}})}
    loan_app
  end
  
end
