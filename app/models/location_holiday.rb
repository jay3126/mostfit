class HolidayInfo

  attr_reader :name, :on_date, :move_work_to_date, :location_type, :location_id

  def initialize(name, on_date, move_work_to_date, location_type, location_id)
    @name = name; @on_date = on_date; @move_work_to_date = move_work_to_date
    @location_type = location_type; @location_id = location_id
  end

end

class LocationHoliday
  include DataMapper::Resource
  include Constants::Space
  
  property :id,                 Serial
  property :name,               String
  property :on_date,            Date, :nullable => false
  property :move_work_to_date,  Date, :nullable => false
  property :location_type,      Enum.send('[]', *MEETINGS_SUPPORTED_AT), :nullable => false
  property :location_id,        Integer, :nullable => false
  property :created_by_user_id, Integer, :nullable => false
  property :created_at,         DateTime, :nullable => false, :default => DateTime.now

  # Returns an instance of HolidayInfo
  def to_info
    HolidayInfo.new(name, on_date, move_work_to_date, location_type, location_id)
  end

  # Creates a holiday for a location
  def self.setup_holiday(location, on_date, move_work_to_date, by_user_id)
    setup(location, on_date, move_work_to_date, by_user_id)
  end

  # This returns the holiday that was created for a specific location
  def self.get_specific_holiday(at_location, on_date)
    holiday = find_holiday(at_location, on_date)
    holiday.nil? ? nil : holiday.to_info
  end

  # This returns any holiday that was created for a location that
  # 'encompasses' the specified location
  def self.get_umbrella_holiday(at_location, on_date)
    ancestors = Constants::Space.all_ancestors(location)
    return nil if ancestors.empty?
    #To be tested
    umbrella_holiday = nil
    ancestors.each { |ancestor_location|
      umbrella_holiday = get_specific_holiday(ancestor_location, on_date)
      return umbrella_holiday if umbrella_holiday
    }
    umbrella_holiday
  end

  # Get either specific holiday or umbrella holiday
  def self.get_any_holiday(at_location, on_date)
    get_specific_holiday(at_location, on_date) || get_umbrella_holiday(at_location, on_date)
  end

  # Get any holiday that applies
  def holiday_applies?(to_location, on_date)
    not (get_any_holiday(to_location, on_date).nil?)
  end

  private

  # Creates a holiday for a location
  def self.setup(location, on_date, move_work_to_date, by_user_id)
    query = predicates_for_location(location)
    query.merge!(:on_date => on_date, :move_work_to_date => move_work_to_date, :created_by_user_id => by_user_id)
    first_or_create(query)
  end

  # Looks for a holiday created specifically for the location on the date
  def self.find_holiday(at_location, on_date)
    query = predicates_for_location_on_date(at_location, on_date)
    first(query)
  end

  # Returns a hash with query parameters for a location
  def self.predicates_for_location(location)
    location_type_string, location_id = Resolver.resolve_location(location)
    {:location_type => location_type_string, :location_id => location_id}
  end

  # Returns a hash with query parameters that match the holiday date
  def self.predicate_to_match_date(on_date)
    {:on_date => on_date}
  end

  # Combines query parameters for location and holiday date
  def self.predicates_for_location_on_date(location, on_date)
    predicates_for_location(location).merge(predicate_to_match_date(on_date))
  end

end