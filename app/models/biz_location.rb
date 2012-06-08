class BizLocation
  include DataMapper::Resource
  include Identified
  
  property :id,         Serial
  property :name,       String, :nullable => false
  property :created_at, DateTime, :nullable => false, :default => DateTime.now
  property :creation_date, Date, :nullable => false, :default => Date.today
  property :deleted_at, ParanoidDateTime

  belongs_to :location_level
  has n, :meeting_schedules, :through => Resource

  has n, :origin_home_staff, :model => 'StaffMember', :child_key => [:origin_home_location_id]

  # Returns all locations that belong to LocationLevel
  def self.all_locations_at_level(by_level_number)
    level = LocationLevel.get_level_by_number(by_level_number)
    all(:location_level => level)
  end

  # Create a new location by specifying the name, the creation date, and the level number (not the level)
  def self.create_new_location(by_name, on_creation_date, at_level_number)
    raise ArgumentError, "Level numbers begin with zero" if (at_level_number < 0)
    level = LocationLevel.get_level_by_number(at_level_number)
    raise Errors::InvalidConfigurationError, "No level was located for the level number: #{at_level_number}" unless level
    location = {}
    location[:name] = by_name
    location[:creation_date] = on_creation_date
    location[:location_level] = level
    new_location = create(location)
    raise Errors::DataError, new_location.errors.first.first unless new_location.saved?
    new_location
  end

  # Gets the name of the LocationLevel that this location belongs to
  def level_name
    self.location_level and self.location_level.name ? self.location_level.name : nil
  end

  # Prints the level name, the name, and the ID
  def to_s
    "#{self.level_name ? self.level_name + " " : ""}#{self.name_and_id}"
  end

  def meeting_schedule_effective(on_date)
    query = {}
    query[:schedule_begins_on.lte] = on_date
    query[:order] = [:schedule_begins_on.desc]
    self.meeting_schedules.first(query)
  end

  def save_meeting_schedule(meeting_schedule)
    self.meeting_schedules << meeting_schedule
    save
  end
  
end
