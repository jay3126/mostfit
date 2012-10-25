class LocationLink
  include DataMapper::Resource
  include Constants::Locations

  property :id,           Serial
  property :effective_on, Date, :nullable => false
  property :model_type, Enum.send('[]', *LINK_MODEL_NAME), :nullable => false
  property :created_at,   DateTime, :nullable => false, :default => DateTime.now
  property :creation_date, Date, :nullable => false, :default => Date.today
  property :parent_id,    Integer, :nullable => false
  property :child_id,     Integer, :nullable => false
  property :deleted_at, ParanoidDateTime

  def parent_location; Resolver.fetch_model_instance(self.model_type, self.parent_id); end
  def child_location; Resolver.fetch_model_instance(self.model_type, self.child_id); end

  validates_with_method :linked_locations_are_at_adjacent_levels?
  validates_with_method :linked_and_creation_dates_are_valid?
  validates_with_method :linked_to_one_location_only_on_one_date?

  # Two locations are related to one another on different location levels and not on the same location level
  def linked_locations_are_at_adjacent_levels?
    if self.model_type == 'BizLocation'
      (self.parent.level_number - self.child.level_number == 1) ? true : [false, "The linked locations are not on valid adjacent levels"]
    else
      true
    end
  end

  def linked_and_creation_dates_are_valid?
    Validators::Assignments.is_valid_assignment_date?(effective_on, self.parent_location, self.child_location)
  end
  
  def linked_to_one_location_only_on_one_date?
    linked_on_same_date = LocationLink.first(:model_type => self.model_type, :child_id => self.child_id, :effective_on => self.effective_on)
    linked_on_same_date ? [false, "The location already has a link to another location made effective on the same date"] : true
  end

  # Get the 'ancestor' or parent for this location link
  def parent
    Resolver.fetch_model_instance(self.model_type, self.parent_id)
  end

  # Get the 'child' or descendant for this location link
  def child
    Resolver.fetch_model_instance(self.model_type, self.child_id)
  end

  # Assign one BizLocation as the child of another as of the specified date
  def self.assign(child, to_parent, on_date = Date.today)

    construction = {}
    construction[:model_type] = child.class.name
    construction[:child_id] = child.id
    construction[:parent_id] = to_parent.id
    construction[:effective_on] = on_date
    link = create(construction)
    raise Errors::DataError, link.errors.first.first unless link.saved?
    link
  end

  # Obtain the parent for a BizLocation on the specified date
  def self.get_parent(for_location, on_date = Date.today)
    parents = {}
    parents[:child_id] = for_location.id
    parents[:effective_on.lte] = on_date
    parents[:model_type] = for_location.class.name
    parents[:order] = [:effective_on.desc]

    parent_links = all(parents)
    parent_link_on_date = parent_links.first
    parent_link_on_date ? parent_link_on_date.parent : nil
  end

  # Obtain the 'children' for a BizLocation on the specified date
  def self.get_children(for_location, on_date = Date.today)
    children_on_date = []
    children = {}
    children[:parent_id] = for_location.id
    children[:model_type] = for_location.class.name
    children[:effective_on.lte] = on_date
    children_links = all(children)
    children_links_grouped = children_links.group_by {|child| child.child_id}
    children_links_grouped.each { |child_id, links|
      sorted_links = links.sort_by {|lnk| lnk.effective_on}
      latest_link = sorted_links.first
      children_on_date << latest_link.child if (latest_link and latest_link.child)
    }
    children_on_date
  end

  def self.all_children(for_location, on_date = Date.today)
    if for_location.location_level.level == 0
      []
    else
      @all_children = []
      location = []
      children = get_children(for_location, on_date)
      children.each do |child|
        location << all_children(child, on_date)
      end
      @all_children = location + children
      @all_children.flatten.compact.uniq
    end
  end

  def self.all_parents(for_location, on_date = Date.today)
    @all_location = []
    location = []
    parent = get_parent(for_location, on_date)
    unless parent.blank?
      location <<  all_parents(parent, on_date)
      @all_location = location << parent
    end
    @all_location.flatten.compact.uniq
  end

  def self.all_children_with_self(for_location, on_date = Date.today)
    all_children(for_location, on_date) << for_location
  end

  def self.all_parents_with_self(for_location, on_date = Date.today)
    all_parents(for_location, on_date) << for_location
  end
end
