class DisbursementLabel < Report

  attr_accessor :biz_location_branch_id, :date, :format

  def initialize(params, date, user)
    @date = date.blank? ? Date.today : date[:date]
    @name = "Report on #{@date}"
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : nil
    @page = params.blank? || params[:page].blank? ? 1 :params[:page]
    @limit = 100
    @user = user
    @format = 'pdf'
    get_parameters(params, user)
  end

  def name
    "Disbursement Label Report on #{@date}"
  end

  def self.name
    "Disbursement Label Report"
  end

  def generate
    if @biz_location_branch
      location = BizLocation.get @biz_location_branch
      location.generate_disbursement_labels_pdf(@user, @date)
    end
  end
end
