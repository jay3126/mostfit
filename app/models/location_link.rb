class LocationLink
  include DataMapper::Resource

  property :id,           Serial
  property :effective_on, Date, :nullable => false
  property :created_at,   DateTime, :nullable => false, :default => DateTime.now
  property :parent_id,    Integer, :nullable => false
  property :child_id,     Integer, :nullable => false

  validates_with_method :linked_locations_are_not_peers?

  # Two locations are related to one another on different location levels and not on the same location level
  def linked_locations_are_not_peers?
    self.parent.location_level == self.child.location_level ?
      [false, "Two locations on the same location level cannot be linked"] : true
  end

  # Get the 'ancestor' or parent for this location link
  def parent
    BizLocation.get(self.parent_id)
  end

  # Get the 'child' or descendant for this location link
  def child
    BizLocation.get(self.child_id)
  end

  # Assign one BizLocation as the child of another as of the specified date
  def self.assign(child, to_parent, on_date = Date.today)
    raise ArgumentError,
      "Locations to be assigned must be instances of BizLocation" unless 
    (child.is_a?(BizLocation) and to_parent.is_a?(BizLocation))

    construction = {}
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

end
