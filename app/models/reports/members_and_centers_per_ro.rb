class MembersAndCentersPerRo < Report

  attr_accessor :date, :biz_location_branch_id

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Member and Centers per RO on #{@date}"
    @user = user
    location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, @user)
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

  def generate
    data = {}
    reporting_facade = FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, @user)

    at_branch_ids_ary = @biz_location_branch.is_a?(Array) ? @biz_location_branch : [@biz_location_branch]
    at_branches = at_branch_ids_ary.blank? ? [] : BizLocation.all(:id => at_branch_ids_ary)
    at_branches.each do |branch|
      all_staff_ids = reporting_facade.staff_members_per_location_on_date(branch.id, @date).aggregate(:staff_id)
      all_staffs = all_staff_ids.blank? ? [] : StaffMember.all(:id => all_staff_ids)
      all_staffs.each do |staff|
        staff_name = staff.name
        centers_members_total = reporting_facade.locations_managed_by_staffs_on_date(staff.id, @date)
        data[staff] = {:branch_id => branch.id, :branch_name => branch.name, :staff_name => staff_name, :staff_id => staff.id, :centers_members_total => centers_members_total}
      end
    end
    data
  end
end