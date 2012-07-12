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
    #TODO
  end

end

module VisitScheduler

  OUTER_LIMIT_OF_DAYS = 60
  SECOND_LIMIT_OF_DAYS = 45

  def schedule_visit(on_date, list_of_all_locations, map_of_assignees, history_of_visits)
=begin

For each round of assignment
select randomly a number of locations from the list of locations (beginning with all locations)
eliminate first or later

=end
  end

  def select_randomly(list_of_elements, number_of_items_to_select)

  end

end