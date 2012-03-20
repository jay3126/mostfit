class CenterCycle
  include DataMapper::Resource
  include Constants::Space

  # In general, each center advances as a whole to a new cycle of loans
  # All activities to disburse new loans are within the 'scope' of this cycle
  # The cycle has a cycle number that identifies it
  # Cycle numbers are monotonically increasing integers starting at 1,
  # and bumped up by one, each time a new cycle is begun at a center
  
  property :id,                    Serial
  property :cycle_number,          Integer, :nullable => false, :min => 1
  property :initiated_by_staff_id, Integer, :nullable => false
  property :initiated_on,          Date, :nullable => false
  property :closed_by_staff_id,    Integer, :nullable => true
  property :closed_on,             Date, :nullable => true
  property :status,                Enum.send('[]', *CENTER_CYCLE_STATUSES), :nullable => false, :default => OPEN_CENTER_CYCLE_STATUS
  property :created_by,            Integer, :nullable => false
  property :created_at,            DateTime, :nullable => false, :default => DateTime.now
  property :updated_at,            DateTime, :nullable => false, :default => DateTime.now

  belongs_to :center, :nullable => false
  
  has n, :loan_applications

  validates_with_method :is_cycle_incremented?

  # The cycle number can only be incremented by one each time
  def is_cycle_incremented?
    latest_cycle_number = CenterCycle.get_current_center_cycle(self.center_id)
    ((self.cycle_number - latest_cycle_number) == 1) ? true :
      [false, "The center cycle can only be advanced to #{(latest_cycle_number + 1)}"]
  end

  # Returns the current center cycle number for a center
  # Returns zero if there are no center cycles created for a center
  def self.get_current_center_cycle(center_id)
    latest = first(:center_id => center_id, :order => [:cycle_number.desc])
    (latest and latest.cycle_number) ? latest.cycle_number : 0
  end

  def self.get_cycle(for_center, by_cycle_number)
    first(:center_id => for_center, :cycle_number => by_cycle_number, :order => [:cycle_number.desc])
  end

  # Encapsulates fetching the status of a center cycle
  def get_cycle_status
    self.status
  end

  # Test for whether this center cycle is still open
  def is_open?
    get_cycle_status == OPEN_CENTER_CYCLE_STATUS
  end

  # Test for whether this center cycle is closed, merely negates test for open
  def is_closed?
    not is_open?
  end

  # Mark the center cycle closed (in preparation for the next center cycle)
  def mark_cycle_closed(by_staff, on_date)
    raise ArgumentError, "cycle close date specified: #{on_date} cannot precede cycle open date #{self.initiated_on}" if (on_date < self.initiated_on)
    self.closed_by_staff_id = by_staff;
    self.closed_on = on_date
    self.status = CLOSED_CENTER_CYCLE_STATUS
    self.save
  end

end
