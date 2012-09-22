class MembersAndCentersPerRo < Report

  attr_accessor :date, :biz_location_branch_id

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Member and Centers per RO on #{@date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : all_branch_ids
    get_parameters(params, user)
  end

  def name
    "Member and Centers per RO on #{@date}"
  end

  def self.name
    "Member and Centers per RO"
  end

  def get_reporting_facade(user)
    @reporting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, user)
  end

  def get_location_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user)
  end

  def get_client_facade(user)
    @client_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::CLIENT_FACADE, user)
  end

  def generate

    data = {}
    location_facade = get_location_facade(@user)
    reporting_facade = get_reporting_facade(@user)
    client_facade = get_client_facade(@user)

    at_branch_ids_ary = @biz_location_branch.is_a?(Array) ? @biz_location_branch : [@biz_location_branch]
    at_branch_ids_ary.each do |branch_id|
      branch = BizLocation.get(branch_id)
      branch_id = branch.id
      branch_name = branch.name
      all_staffs = reporting_facade.staff_members_per_location_on_date(branch_id, @date).aggregate(:staff_id)
      all_staffs.each do |s|
        staff = StaffMember.get(s)
        staff_id = staff.id
        staff_name = staff.name
        centers_members_total = reporting_facade.locations_managed_by_staffs_on_date(staff.id, @date)
        data[s] = {:branch_id => branch_id, :branch_name => branch_name, :staff_name => staff_name, :staff_id => staff_id, :centers_members_total => centers_members_total}
      end
    end
    data
  end
end
