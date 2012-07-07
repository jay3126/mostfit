require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a dropdownpoint_filling exists" do
  DropdownpointFilling.all.destroy!
  request(resource(:dropdownpoint_fillings), :method => "POST", 
    :params => { :dropdownpoint_filling => { :id => nil }})
end

describe "resource(:dropdownpoint_fillings)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:dropdownpoint_fillings))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of dropdownpoint_fillings" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a dropdownpoint_filling exists" do
    before(:each) do
      @response = request(resource(:dropdownpoint_fillings))
    end
    
    it "has a list of dropdownpoint_fillings" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      DropdownpointFilling.all.destroy!
      @response = request(resource(:dropdownpoint_fillings), :method => "POST", 
        :params => { :dropdownpoint_filling => { :id => nil }})
    end
    
    it "redirects to resource(:dropdownpoint_fillings)" do
      @response.should redirect_to(resource(DropdownpointFilling.first), :message => {:notice => "dropdownpoint_filling was successfully created"})
    end
    
  end
end

describe "resource(@dropdownpoint_filling)" do 
  describe "a successful DELETE", :given => "a dropdownpoint_filling exists" do
     before(:each) do
       @response = request(resource(DropdownpointFilling.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:dropdownpoint_fillings))
     end

   end
end

describe "resource(:dropdownpoint_fillings, :new)" do
  before(:each) do
    @response = request(resource(:dropdownpoint_fillings, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@dropdownpoint_filling, :edit)", :given => "a dropdownpoint_filling exists" do
  before(:each) do
    @response = request(resource(DropdownpointFilling.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@dropdownpoint_filling)", :given => "a dropdownpoint_filling exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(DropdownpointFilling.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @dropdownpoint_filling = DropdownpointFilling.first
      @response = request(resource(@dropdownpoint_filling), :method => "PUT", 
        :params => { :dropdownpoint_filling => {:id => @dropdownpoint_filling.id} })
    end
  
    it "redirect to the dropdownpoint_filling show action" do
      @response.should redirect_to(resource(@dropdownpoint_filling))
    end
  end
  
end

