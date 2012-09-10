class AdvancePaymentsCurrentReport < Report
  attr_accessor :date

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Advance Payment Current Report on #{@date}"
    @user = user
    get_parameters(params, user)
  end

  def name
    "Advance Payment Current Report on #{@date}"
  end

  def self.name
    "Advance Payment Current Report"
  end
  def managed_by_staff(location_id, on_date)
    location_facade = get_location_facade(@user)
    location_manage = location_facade.location_managed_by_staff(location_id, on_date)
    if location_manage.blank?
      'Not Managed'
    else
      staff_member = location_manage.manager_staff_member.name
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
    loan_receipts = LoanReceipt.all(:advance_received.gt => 0, :effective_on => @date).group_by{|l| l.lending}
    loan_receipts.each do |loan, receipts|
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
      advance_payment            = Money.new(receipts.map(&:advance_received).sum.to_i, default_currency)
      center                     = loan.administered_at_origin_location
      center_id                  = center ? center.id : "Not Specified"
      center_name                = center ? center.name : "Not Specified"
      branch                     = loan.accounted_at_origin_location
      branch_name                = branch ? branch.name : "Not Specified"
      branch_id                  = branch ? branch.id : "Not Specified"
      fco_name                   = center.blank? ? "Not Specified" : managed_by_staff(center.id, @date)

      data[loan.id] = {:member_name => member_name, :member_id => member_id,
        :center_name => center_name, :center_id => center_id, :loan_account_number => loan_account_number,
        :branch_name => branch_name, :branch_id => branch_id,
        :loan_id => loan_id, :fco_name => fco_name, :advance_payment => advance_payment}
    end
    data
  end

end
