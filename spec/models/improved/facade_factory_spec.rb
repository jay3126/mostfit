require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe FacadeFactory do

  before(:all) do
    @for_user = Factory(:user)
    @facade_factory = FacadeFactory.instance
  end

  it "should return an instance of the requested StandardFacade" do
    FacadeFactory::STANDARD_FACADES.each { |key, value|
      facade_instance = @facade_factory.get_instance(key, @for_user)
      facade_instance.should be_an_instance_of value
    }
  end

  it "should return an instance of the requested SingletonFacade" do
    FacadeFactory::SINGLETON_FACADES.each { |key, value|
      facade_instance = @facade_factory.get_instance(key, @for_user)
      facade_instance.should be_an_instance_of value
    }
  end

  it "should raise an error if it is requested for an instance of a facade that does not exist" do
    non_existent_facade = :non_existent_facade
    FacadeFactory::STANDARD_FACADES.include?(non_existent_facade).should be_false
    FacadeFactory::SINGLETON_FACADES.include?(non_existent_facade).should be_false
    lambda {@facade_factory.get_instance(:non_existent_facade)}.should raise_error
  end

  it "should return an instance of the requested StandardFacade given an instance of another StandardFacade" do
    location_facade = @facade_factory.get_instance(FacadeFactory::LOCATION_FACADE, @for_user)
    facade_instance_requested = @facade_factory.get_other_facade(FacadeFactory::MEETING_FACADE, location_facade)
    facade_instance_requested.should be_an_instance_of FacadeFactory::STANDARD_FACADES[FacadeFactory::MEETING_FACADE]
  end

end
