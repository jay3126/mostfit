require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LocationLink do

  it "should disallow linking locations that are at the same location level"

  it "should assign a location to another on the specified date"

  it "should only allow zero or one parent location for a location on a specified date"

  it "should return a child location as expected"

  it "should return a parent location as expected"

  it "should return the parent location for a location on the specified date"

  it "should return nil for the parent location for a specified date when there is no such link for the location"

  it "should return the child locations for a location on the specified date"

  it "should return an empty list for children when a location does not have child locations on a specified date"

end