require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a priority_sector_list exists" do
  PrioritySectorList.all.destroy!
  request(resource(:priority_sector_lists), :method => "POST", 
    :params => { :priority_sector_list => { :id => nil }})
end

describe "resource(:priority_sector_lists)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:priority_sector_lists))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of priority_sector_lists" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a priority_sector_list exists" do
    before(:each) do
      @response = request(resource(:priority_sector_lists))
    end
    
    it "has a list of priority_sector_lists" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      PrioritySectorList.all.destroy!
      @response = request(resource(:priority_sector_lists), :method => "POST", 
        :params => { :priority_sector_list => { :id => nil }})
    end
    
    it "redirects to resource(:priority_sector_lists)" do
      @response.should redirect_to(resource(PrioritySectorList.first), :message => {:notice => "priority_sector_list was successfully created"})
    end
    
  end
end

describe "resource(@priority_sector_list)" do 
  describe "a successful DELETE", :given => "a priority_sector_list exists" do
     before(:each) do
       @response = request(resource(PrioritySectorList.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:priority_sector_lists))
     end

   end
end

describe "resource(:priority_sector_lists, :new)" do
  before(:each) do
    @response = request(resource(:priority_sector_lists, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@priority_sector_list, :edit)", :given => "a priority_sector_list exists" do
  before(:each) do
    @response = request(resource(PrioritySectorList.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@priority_sector_list)", :given => "a priority_sector_list exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(PrioritySectorList.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @priority_sector_list = PrioritySectorList.first
      @response = request(resource(@priority_sector_list), :method => "PUT", 
        :params => { :priority_sector_list => {:id => @priority_sector_list.id} })
    end
  
    it "redirect to the priority_sector_list show action" do
      @response.should redirect_to(resource(@priority_sector_list))
    end
  end
  
end

