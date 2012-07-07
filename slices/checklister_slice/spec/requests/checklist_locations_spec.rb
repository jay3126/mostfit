require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a checklist_location exists" do
  ChecklistLocation.all.destroy!
  request(resource(:checklist_locations), :method => "POST", 
    :params => { :checklist_location => { :id => nil }})
end

describe "resource(:checklist_locations)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:checklist_locations))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of checklist_locations" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a checklist_location exists" do
    before(:each) do
      @response = request(resource(:checklist_locations))
    end
    
    it "has a list of checklist_locations" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      ChecklistLocation.all.destroy!
      @response = request(resource(:checklist_locations), :method => "POST", 
        :params => { :checklist_location => { :id => nil }})
    end
    
    it "redirects to resource(:checklist_locations)" do
      @response.should redirect_to(resource(ChecklistLocation.first), :message => {:notice => "checklist_location was successfully created"})
    end
    
  end
end

describe "resource(@checklist_location)" do 
  describe "a successful DELETE", :given => "a checklist_location exists" do
     before(:each) do
       @response = request(resource(ChecklistLocation.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:checklist_locations))
     end

   end
end

describe "resource(:checklist_locations, :new)" do
  before(:each) do
    @response = request(resource(:checklist_locations, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@checklist_location, :edit)", :given => "a checklist_location exists" do
  before(:each) do
    @response = request(resource(ChecklistLocation.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@checklist_location)", :given => "a checklist_location exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(ChecklistLocation.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @checklist_location = ChecklistLocation.first
      @response = request(resource(@checklist_location), :method => "PUT", 
        :params => { :checklist_location => {:id => @checklist_location.id} })
    end
  
    it "redirect to the checklist_location show action" do
      @response.should redirect_to(resource(@checklist_location))
    end
  end
  
end

