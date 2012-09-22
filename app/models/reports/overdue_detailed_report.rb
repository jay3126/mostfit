class OverdueDetailedReport < Report
  attr_accessor :biz_location_branch_id, :date

  validates_with_method :biz_location_branch_id, :branch_should_be_selected

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Overdue Detailed Report"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : all_branch_ids
    get_parameters(params, user)
  end

  def name
    "Overdue Detailed Report for #{@date}"
  end

  def self.name
    "Overdue Detailed Report"
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

  def set_overdue_days_range(days)
    case days.to_i
    when 0..40
      '1-40 Days'
    when 40..80
      '41-80 Days'
    when 80..120
      '81-120 Days'
    when 121..160
      '121-160 Days'
    when 161..180
      '161-180 Days'
    else
      '180+ Days'
    end
  end

  def generate

    data = {}
    outstanding_loans = get_reporting_facade(@user).all_outstanding_loans_on_date(@date, @biz_location_branch)
    lendings = outstanding_loans.select {|loan| (loan.days_past_due > 0)}
    lendings.each do |loan|
      
      loan_due_status            = loan.loan_due_statuses(:due_status => Constants::Loan::DUE, :order => [:on_date.desc, :created_at.desc]).first
      loan_overdue_status        = loan.loan_due_statuses(:due_status => Constants::Loan::OVERDUE, :on_date.lte => @date, :order => [:on_date.desc, :created_at.desc]).last

      unless loan_overdue_status.blank?
        member                    = loan.loan_borrower.counterparty
        if member.blank?
          member_id = 'Not Specified'
          member_name = 'Not Specified'
        else
          member_id       = member.id
          member_name     = member.name
        end
        loan_product_name      = (loan and loan.lending_product and (not loan.nil?)) ? loan.lending_product.name : "Loan Product Not Available"
        funding_line           = FundingLineAddition.all(:lending_id => loan.id)
        source_of_fund             = (funding_line and (not funding_line.blank?)) ? FundingLine.get(funding_line.first.funding_line_id).name : "Source of Fund not Available"
        loan_account_number        = (loan and (not loan.nil?)) ? loan.lan : "Not Specified"
        loan_disbursed_date        = (loan and loan.disbursal_date and (not loan.nil?)) ? loan.disbursal_date : "Disbursal Date Not Available"
        loan_end_date              = (loan and loan.last_scheduled_date and (not loan.nil?)) ? loan.last_scheduled_date : "End Date Not Available"
        oldest_due_date            = (loan_due_status and (not loan_due_status.nil?)) ? loan_due_status.on_date : "Status Not Available"
        days_past_due              = loan.days_past_due_on_date(@date)
        bucket                     = set_overdue_days_range(days_past_due)
        total_principal_overdue    = loan_overdue_status.to_money[:actual_principal_outstanding]
        total_interest_overdue     = loan_overdue_status.to_money[:actual_interest_outstanding]
        total_overdue              = loan_overdue_status.to_money[:actual_total_outstanding]
        par                        = total_principal_overdue
        center                     = loan.administered_at_origin_location
        center_id                  = center ? center.id : "Not Specified"
        center_name                = center ? center.name : "Not Specified"
        branch                     = loan.accounted_at_origin_location
        branch_name                = branch ? branch.name : "Not Specified"
        branch_id                  = branch ? branch.id : "Not Specified"

        data[loan.id] = {:member_name => member_name, :member_id => member_id,
          :center_name => center_name, :center_id => center_id, :loan_account_number => loan_account_number,
          :branch_name => branch_name, :branch_id => branch_id,
          :product_name => loan_product_name, :source_of_fund => source_of_fund,
          :loan_disbursed_date => loan_disbursed_date, :loan_end_date => loan_end_date,
          :oldest_due_date => oldest_due_date, :days_past_due => days_past_due,
          :bucket => bucket, :total_principal_overdue => total_principal_overdue, :total_interest_overdue => total_interest_overdue,
          :total_overdue => total_overdue, :par =>  par
        }
      end
    end
    data
  end

  def branch_should_be_selected
    return [false, "Branch needs to be selected"] if self.respond_to?(:biz_location_branch_id) and not self.biz_location_branch_id
    return true
  end
end
