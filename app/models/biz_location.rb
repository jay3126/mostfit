class BizLocation
  include DataMapper::Resource
  include Identified
  
  property :id,         Serial
  property :name,       String, :nullable => false
  property :created_at, DateTime, :nullable => false, :default => DateTime.now
  property :creation_date, Date, :nullable => false, :default => Date.today
  property :deleted_at, ParanoidDateTime

  # Mapping with Biz-Location to Meeting Schedule
  has n, :meeting_schedules, :through => Resource
  belongs_to :location_level

  # Returns all locations that are belong to LocationLevel
  def self.all_locations_at(location_level)
    raise ArgumentError, "Please supply an instance of LocationLevel" unless location_level.is_a?(LocationLevel)
    all(:location_level => location_level)
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
  
end
