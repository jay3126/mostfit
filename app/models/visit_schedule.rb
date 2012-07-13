class VisitSchedule
  include DataMapper::Resource
  include Constants::Properties

  property :id, Serial
  property :was_visited, Boolean, :default => false
  property :visit_scheduled_date, *DATE_NOT_NULL
  property :visited_on, Date
  property :created_at, *CREATED_AT

  belongs_to :staff_member
  belongs_to :biz_location #this is a center

  MAX_SCHEDULED_PER_DAY_AT_BRANCH = 7

  SYMBOLIC_DESIGNATION_TO_ROLE_CLASSES_MAP = {
    :branch_manager => Constants::User::SUPERVISOR, :audit_officer => Constants::User::SUPPORT
  }

  COUNT_VISITS_TO_ASSIGN_BY_DESIGNATION = {
    :branch_manager => 3, :audit_officer => 2
  }

  def self.schedule_visits(under_branch_id, on_date)    
    existing_visit_count_on_date = (all(:biz_location_id => under_branch_id, :visit_scheduled_date => on_date)).count
    return unless existing_visit_count_on_date == 0

    history_of_visits = visit_history_at_branch(under_branch_id, on_date)
    return if history_of_visits.empty?
    scheduler = MyVisitScheduler.new
    visits_to_schedule = scheduler.schedule_visit(on_date, COUNT_VISITS_TO_ASSIGN_BY_DESIGNATION, history_of_visits)
    staff_members = get_staff_member_ids(COUNT_VISITS_TO_ASSIGN_BY_DESIGNATION.keys, under_branch_id, on_date)

    visits_to_schedule.each { |staff_member_designation, center_ids_to_visit|
      staff_member = staff_members[staff_member_designation]
      next unless staff_member
      center_ids_to_visit.each { |center_id|
        VisitSchedule.first_or_create(
          :was_visited => false,
          :visit_scheduled_date => on_date,
          :staff_member_id => staff_member.id,
          :biz_location_id => center_id
        )
      }
    }
  end

  def self.get_staff_member_ids(for_designations, under_branch_id, on_date)
    staff_members_for_designations = {}
    user_facade = FacadeFactory.instance.get_instance(FacadeFactory::USER_FACADE, nil)
    operator = user_facade.get_operator
    raise Errors::InvalidConfigurationError, "An operator user was not found" unless operator

    choice_facade = FacadeFactory.instance.get_instance(FacadeFactory::CHOICE_FACADE, operator)

    for_designations.each_with_index { |designation, idx|
      role_class = SYMBOLIC_DESIGNATION_TO_ROLE_CLASSES_MAP[designation]
      staff_members = choice_facade.get_staff_members_for_role_class(role_class, under_branch_id, on_date)
      staff_members_for_designations[designation] = staff_members.first if (staff_members and staff_members.first)
    }
    staff_members_for_designations
  end

  def self.scvs_by_visit_status(at_location_id, on_date)
    visit_schedules = all(:biz_location_id => at_location_id, :scheduled_on => on_date)
  end

  def self.visit_history_at_branch(branch_id, on_date, past_number_of_days = VisitScheduler::OUTER_LIMIT_OF_DAYS)
    user_facade = FacadeFactory.instance.get_instance(FacadeFactory::USER_FACADE, nil)
    operator = user_facade.get_operator
    raise Errors::InvalidConfigurationError, "An operator user was not found" unless operator

    location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, operator)
    branch = BizLocation.get(branch_id)
    centers = location_facade.get_children(branch, on_date)
    return [] unless (centers and (not (centers.empty?)))

    date_lower_limit = on_date - past_number_of_days
    center_visit_history = {}
    centers.each { |center|
      visit_count = (center.visit_schedules.all(:was_visited => true, :visited_on.gte => date_lower_limit)).count
      center_visit_history[center.id] = (visit_count > 0)
    }
    center_visit_history
  end

  def self.visit_history(on_date, past_number_of_days = VisitScheduler::OUTER_LIMIT_OF_DAYS)
    facade=FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, User.first)
    @centers=facade.all_nominal_centers
    history_details=Hash.new
    @centers.each do |center|
      if center.visit_schedules.all(:was_visited => true, :visited_on.lte => (on_date-past_number_of_days)).count>0
        flag=true
      else
        flag=false
      end
      history_details[center.id] = flag
    end
    return history_details
  end

end

module VisitScheduler

  OUTER_LIMIT_OF_DAYS = 60
  SECOND_LIMIT_OF_DAYS = 45

  def schedule_visit(on_date, map_of_assignees, history_of_visits)

    list_of_all_locations = history_of_visits.keys
    list_of_visited_locations=filter_visited_locations_list(list_of_all_locations, history_of_visits)
    list_of_unvisited_locations=list_of_all_locations-list_of_visited_locations


    if list_of_visited_locations.nil?
      list_of_visited_locations=Array.new
    end
    if list_of_unvisited_locations.nil?
      list_of_unvisited_locations=Array.new
    end

    scheduling=Hash.new
    map_of_assignees.each do |key, value|
      if list_of_unvisited_locations.length.to_i >= value.to_i
        selected_locations=select_randomly(list_of_unvisited_locations, value)
      else
        selected_locations=select_randomly(list_of_unvisited_locations,list_of_unvisited_locations.length)#+select_randomly(list_of_visited_locations, (value-list_of_unvisited_locations.length))
      end

      list_of_unvisited_locations=list_of_unvisited_locations-selected_locations
      list_of_visited_locations=(list_of_visited_locations+selected_locations)

      scheduling[key]=selected_locations
    end
    return scheduling
  end

  def select_randomly(list_of_elements, number_of_items_to_select)
    if number_of_items_to_select>list_of_elements.length
      return "Cannot select #{number_of_items_to_select} items from #{list_of_elements.length} items"
    else
      random_keys=list_of_elements.shuffle[0..(number_of_items_to_select-1)]
      randomly_selected_list=Array.new
      randomly_selected_list=random_keys
      return randomly_selected_list
    end

  end

  def filter_visited_locations_list(list_of_centers, history_of_visits)
    list_of_centers=list_of_centers.to_hash
    if list_of_centers.length!=history_of_visits.length
      return "The Arguments have some issues."

    else
      visited_locations=Array.new
      list_of_centers.each do |key, value|
        if history_of_visits[key]
          visited_locations<<key
        end
      end
      return visited_locations
    end

  end

end

class MyVisitScheduler
  include VisitScheduler

  attr_reader :created_at
  def initialize; @created_at = DateTime.now; end
end