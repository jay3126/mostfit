require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a dropdownpoint exists" do
  Dropdownpoint.all.destroy!
  request(resource(:dropdownpoints), :method => "POST", 
    :params => { :dropdownpoint => { :id => nil }})
end

describe "resource(:dropdownpoints)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:dropdownpoints))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of dropdownpoints" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a dropdownpoint exists" do
    before(:each) do
      @response = request(resource(:dropdownpoints))
    end
    
    it "has a list of dropdownpoints" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Dropdownpoint.all.destroy!
      @response = request(resource(:dropdownpoints), :method => "POST", 
        :params => { :dropdownpoint => { :id => nil }})
    end
    
    it "redirects to resource(:dropdownpoints)" do
      @response.should redirect_to(resource(Dropdownpoint.first), :message => {:notice => "dropdownpoint was successfully created"})
    end
    
  end
end

describe "resource(@dropdownpoint)" do 
  describe "a successful DELETE", :given => "a dropdownpoint exists" do
     before(:each) do
       @response = request(resource(Dropdownpoint.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:dropdownpoints))
     end

   end
end

describe "resource(:dropdownpoints, :new)" do
  before(:each) do
    @response = request(resource(:dropdownpoints, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@dropdownpoint, :edit)", :given => "a dropdownpoint exists" do
  before(:each) do
    @response = request(resource(Dropdownpoint.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@dropdownpoint)", :given => "a dropdownpoint exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Dropdownpoint.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @dropdownpoint = Dropdownpoint.first
      @response = request(resource(@dropdownpoint), :method => "PUT", 
        :params => { :dropdownpoint => {:id => @dropdownpoint.id} })
    end
  
    it "redirect to the dropdownpoint show action" do
      @response.should redirect_to(resource(@dropdownpoint))
    end
  end
  
end

