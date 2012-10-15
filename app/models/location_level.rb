class LocationLevel
  include DataMapper::Resource
  include Identified

  NOMINAL_BRANCH_LEVEL = 1; NOMINAL_BRANCH_LEVEL_NAME = "Branch"
  NOMINAL_CENTER_LEVEL = 0; NOMINAL_CENTER_LEVEL_NAME = "Center"
  DESIGNATIONS_CANNOT_BE_CREATED_AT_LEVELS = [NOMINAL_CENTER_LEVEL]  

  DEFAULT_LEVELS = [NOMINAL_CENTER_LEVEL, NOMINAL_BRANCH_LEVEL]
  DEFAULT_LEVELS_AND_ATTRIBUTES = {
    NOMINAL_CENTER_LEVEL =>
      {:level => NOMINAL_CENTER_LEVEL, :name => NOMINAL_CENTER_LEVEL_NAME, :has_meeting => true, :creation_date => Constants::Time::EARLIEST_DATE_OF_OPERATION},
    NOMINAL_BRANCH_LEVEL =>
      {:level => NOMINAL_BRANCH_LEVEL, :name => NOMINAL_BRANCH_LEVEL_NAME, :creation_date => Constants::Time::EARLIEST_DATE_OF_OPERATION},
  }
  
  property :id,            Serial
  property :level,         Integer,         :nullable => false, :unique => true, :min => 0
  property :name,          String,          :nullable => false
  property :has_meeting,   Boolean,         :nullable => false, :default=> false
  property :created_at,    DateTime,        :nullable => false, :default => DateTime.now
  property :creation_date, Date,            :nullable => false, :default => Date.today
  property :deleted_at,    ParanoidDateTime

  validates_is_unique :name

  has n, :biz_locations
  belongs_to :upload, :nullable => true

  def created_on; self.creation_date; end

  #method for upload functionality.
  def self.from_csv(row, headers)
    obj = new(:name => row[headers[:name]], :level => row[headers[:level]], :creation_date => row[headers[:creation_date]],
              :upload_id => row[headers[:upload_id]])
    [obj.save, obj]
  end

  # This initialises the basic location levels needed, and must be invooked at startup
  def self.setup_defaults
    DEFAULT_LEVELS_AND_ATTRIBUTES.values.each { |attributes|
      first_or_create(attributes)
    }
  end

  def self.lowest_level
    first(:order => [:level.asc])
  end

  def self.highest_level
    first(:order => [:level.desc])
  end

  # Creates the next level, by incrementing the level number
  def self.create_next_level(name, on_creation_date)
    new_level = {}
    new_level[:name] = name
    new_level[:creation_date] = on_creation_date
    new_level[:level] = level_number_for_new
    new_location_level = create(new_level)
    raise Errors::DataError, new_location_level.errors.first.first unless new_location_level.saved?
    new_location_level
  end

  # Returns the number for the next level
  def self.level_number_for_new
    level_number_range ? (level_number_range.max + 1) : 0
  end

  # Returns a Range for the existing level numbers
  def self.level_number_range
    all.blank? ? nil : (LocationLevel.first.level..LocationLevel.last.level)
  end

  # Locates a level given the number
  def self.get_level_by_number(given_number)
    return nil unless level_number_range
    raise ArgumentError, "The level number specified does not exist. Try a number between #{level_number_range.min} and #{level_number_range.max}" unless
        level_number_range === given_number
    first(:level => given_number)
  end


  def self.levels_that_support_designations
    all.reject {|level_instance| DESIGNATIONS_CANNOT_BE_CREATED_AT_LEVELS.include?(level_instance.level)}
  end  

end
