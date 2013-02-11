class LoanCollectionsDetailReport < Report

  attr_accessor :biz_location_branch_id, :date, :file_format

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Loan Collections Detail Report on #{@date}"
    @user = user
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : []
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
    reporting_facade = get_reporting_facade(@user)
    location = @biz_location_branch.blank? ? nil : BizLocation.get(@biz_location_branch)
    all_center_ids_array = @biz_location_branch.blank? ? [] : LocationLink.all_children_by_sql(location, @date)
    center_ids_repayment_on_date = all_center_ids_array.blank? ? [] : Lending.all(:administered_at_origin => all_center_ids_array.map(&:id), 'loan_base_schedule.base_schedule_line_items.on_date' => @date).aggregate(:administered_at_origin) rescue []
    centers_repayment_on_date = center_ids_repayment_on_date.blank? ? [] : BizLocation.all(:id => center_ids_repayment_on_date)
    centers_repayment_on_date.each do |center|
      center_id = center.id
      center_name = center ? center.name : "Not Specified"
      branch = location
      branch_name = branch ? branch.name : "Not Specified"
      dues_collected_and_collectable = reporting_facade.total_schedule_collected_and_collectable_per_center_on_date(center_id, @date)
      receipt_number = ""
      staff_name = dues_collected_and_collectable[:managed_by_staff]
      data[staff_name] = [] if data[staff_name].blank?
      if dues_collected_and_collectable[:scheduled_total] > MoneyManager.default_zero_money
        data[staff_name] << {:staff_name => staff_name, :branch_name => branch_name, :center_name => center_name, :dues_collected_and_collectable => dues_collected_and_collectable, :receipt_number => receipt_number}
      end
    end
    data
  end

  def generate_xls
    locations = @biz_location_branch.blank? ? BizLocation.all('location_level.level' => 1) : [BizLocation.get(@biz_location_branch)]
    name = @biz_location_branch.blank? ? 'all_branches' : locations.first.name
    data = {}
    reporting_facade = get_reporting_facade(@user)
    locations.each do |location|
      data[location.name] = {}
      all_center_ids_array = LocationLink.all_children_by_sql(location, @date)
      center_ids_repayment_on_date = all_center_ids_array.blank? ? [] : Lending.all(:administered_at_origin => all_center_ids_array.map(&:id), 'loan_base_schedule.base_schedule_line_items.on_date' => @date).aggregate(:administered_at_origin) rescue []
      centers_repayment_on_date = center_ids_repayment_on_date.blank? ? [] : BizLocation.all(:id => center_ids_repayment_on_date)
      centers_repayment_on_date.each do |center|
        center_id = center.id
        center_name = center ? center.name : "Not Specified"
        branch = location
        branch_name = branch ? branch.name : "Not Specified"
        dues_collected_and_collectable = reporting_facade.total_schedule_collected_and_collectable_per_center_on_date(center_id, @date)
        receipt_number = ""
        staff_name = dues_collected_and_collectable[:managed_by_staff]
        data[location.name][staff_name] = [] if data[location.name][staff_name].blank?
        if dues_collected_and_collectable[:scheduled_total] > MoneyManager.default_zero_money
          data[location.name][staff_name] << {:staff_name => staff_name, :branch_name => branch_name, :center_name => center_name, :dues_collected_and_collectable => dues_collected_and_collectable, :receipt_number => receipt_number}
        end
      end
    end
    folder = File.join(Merb.root, "doc", "xls", "company",'reports', self.class.name.split(' ').join())
    FileUtils.mkdir_p(folder)
    csv_loan_file = File.join(folder, "loan_collections_detail_report_#{name}_#{@date.to_s}.csv")
    File.new(csv_loan_file, "w").close
    append_to_file_as_csv(headers, csv_loan_file)
    data.each do |location_name, location_values|
      location_values.each do |staff_name, values|
        values.each do |s_value|
          value = [s_value[:branch_name], s_value[:staff_name], s_value[:center_name], s_value[:dues_collected_and_collectable][:scheduled_total], s_value[:dues_collected_and_collectable][:total_received], s_value[:receipt_number]]
          append_to_file_as_csv([value], csv_loan_file)
        end
      end
    end
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
    _headers ||= [["Branch Name", "Staff Name", "Center Name", "Dues Collectable", "Dues Collected", "Receipt Number"]]
  end
end
