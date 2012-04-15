module IsLocation
  include Identified

  def location_type
    Constants::Space.to_location_type(self)
  end
  
  def ancestor
    ancestor_type = Constants::Space.ancestor_type(self)
    return nil unless ancestor_type
    send(ancestor_type) if (ancestor_type and respond_to?(ancestor_type))
  end

  def descendants
    descendant_association = Constants::Space.descendant_association(self)
    return nil unless descendant_association
    send(descendant_association) if (descendant_association and respond_to?(descendant_association))
  end

end