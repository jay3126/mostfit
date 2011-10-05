require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a village exists" do
  Village.all.destroy!
  request(resource(:villages), :method => "POST", 
    :params => { :village => { :id => nil }})
end

describe "resource(:villages)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:villages))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of villages" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a village exists" do
    before(:each) do
      @response = request(resource(:villages))
    end
    
    it "has a list of villages" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Village.all.destroy!
      @response = request(resource(:villages), :method => "POST", 
        :params => { :village => { :id => nil }})
    end
    
    it "redirects to resource(:villages)" do
      @response.should redirect_to(resource(Village.first), :message => {:notice => "village was successfully created"})
    end
    
  end
end

describe "resource(@village)" do 
  describe "a successful DELETE", :given => "a village exists" do
     before(:each) do
       @response = request(resource(Village.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:villages))
     end

   end
end

describe "resource(:villages, :new)" do
  before(:each) do
    @response = request(resource(:villages, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@village, :edit)", :given => "a village exists" do
  before(:each) do
    @response = request(resource(Village.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@village)", :given => "a village exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Village.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @village = Village.first
      @response = request(resource(@village), :method => "PUT", 
        :params => { :village => {:id => @village.id} })
    end
  
    it "redirect to the village show action" do
      @response.should redirect_to(resource(@village))
    end
  end
  
end

