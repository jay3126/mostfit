class LoanCollectionsDetailReport < Report

  attr_accessor :biz_location_branch, :date

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Loan Collections Detail Report on #{@date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch] and (not (params[:biz_location_branch].empty?))) ? params[:biz_location_branch] : all_branch_ids
    get_parameters(params, user)
  end

  def name
    "Loan Collections Detail Report on #{@date}"
  end

  def self.name
    "Loan Collections Detail Report"
  end

  def get_reporting_facade(user)
    @reporting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, user)
  end

  def get_location_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user)
  end

  def generate

    data = {}
    location_facade = get_location_facade(@user)
    reporting_facade = get_reporting_facade(@user)
    all_center_ids_array = []

    if @biz_location_branch.class == Fixnum
      all_center_ids_array = location_facade.get_children(BizLocation.get(@biz_location_branch), @date).map{|bl| bl.id}
    else
      locations = @biz_location_branch.each do |b|
        all_center_ids_array << location_facade.get_children(BizLocation.get(b), @date).map{|blz| blz.id}
      end
    end

    all_center_ids_array.flatten.each do |center_id|
      center = BizLocation.get(center_id)
      center_ids = center ? center.id : "Not Specified"
      center_name = center ? center.name : "Not Specified"
      branch = location_facade.get_parent(BizLocation.get(center_id), @date)
      branch_id = branch ? branch.id : "Not Specified"
      branch_name = branch ? branch.name : "Not Specified"
      dues_collected_and_collectable = reporting_facade.total_dues_collected_and_collectable_per_location_on_date(center_id, @date)
      receipt_number = "Not Specified"

      data[center] = {:branch_id => branch_id, :branch_name => branch_name, :center_id => center_id, :center_name => center_name, :dues_collected_and_collectable => dues_collected_and_collectable, :receipt_number => receipt_number}
    end
    data
  end
end
