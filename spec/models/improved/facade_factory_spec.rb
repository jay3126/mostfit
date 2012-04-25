require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe FacadeFactory do

  before(:all) do
    @for_user = Factory(:user)
  end

  it "should return an instance of the requested StandardFacade" do
    FacadeFactory::FACADE_TYPES.each { |key, value|
      facade_instance = FacadeFactory.instance.get_instance(key, @for_user)
      facade_instance.should be_an_instance_of value
    }
  end

  it "should return an instance of the requested StandardFacade given an instance of another StandardFacade" do
    facade_factory = FacadeFactory.instance
    location_facade = facade_factory.get_instance(FacadeFactory::LOCATION_FACADE, @for_user)
    facade_instance_requested = facade_factory.get_other_facade(FacadeFactory::MEETING_FACADE, location_facade)
    facade_instance_requested.should be_an_instance_of FacadeFactory::FACADE_TYPES[FacadeFactory::MEETING_FACADE]
  end

end
