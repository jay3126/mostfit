class VisitSchedule
  include DataMapper::Resource
  include Constants::Properties

  property :id, Serial
  property :was_visited, Boolean, :default => false
  property :visit_scheduled_date, *DATE_NOT_NULL
  property :scheduled_on, Date, :nullable => false
  property :visited_on, Date
  property :created_at, *CREATED_AT

  belongs_to :staff_member
  belongs_to :biz_location

  def self.schedule_visit_on_date(on_date, for_staff_member, to_location)
    #TODO
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

  def schedule_visit(on_date, list_of_all_locations, map_of_assignees, history_of_visits)

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
        selected_locations=list_of_unvisited_locations+select_randomly(list_of_visited_locations, (value-list_of_unvisited_locations.length))
      end


      list_of_unvisited_locations=list_of_unvisited_locations-selected_locations
      list_of_visited_locations=(list_of_visited_locations+selected_locations)


      scheduling[key]=selected_locations


    end

    return scheduling


=begin


For each round of assignment
select randomly a number of locations from the list of locations (beginning with all locations)
eliminate first or later

=end
  end

  def select_randomly(list_of_elements, number_of_items_to_select)
    if number_of_items_to_select>list_of_elements.length
      return "Mathematical Problem in the arguments"

    else
      random_keys=list_of_elements.shuffle[0..(number_of_items_to_select-1)]
      randomly_selected_list=Array.new
      #random_keys.each do |key|
      #  randomly_selected_list<<list_of_elements[key]
      #end
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