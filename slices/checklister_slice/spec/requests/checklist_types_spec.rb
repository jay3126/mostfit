require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a checklist_type exists" do
  ChecklistType.all.destroy!
  request(resource(:checklist_types), :method => "POST", 
    :params => { :checklist_type => { :id => nil }})
end

describe "resource(:checklist_types)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:checklist_types))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of checklist_types" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a checklist_type exists" do
    before(:each) do
      @response = request(resource(:checklist_types))
    end
    
    it "has a list of checklist_types" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      ChecklistType.all.destroy!
      @response = request(resource(:checklist_types), :method => "POST", 
        :params => { :checklist_type => { :id => nil }})
    end
    
    it "redirects to resource(:checklist_types)" do
      @response.should redirect_to(resource(ChecklistType.first), :message => {:notice => "checklist_type was successfully created"})
    end
    
  end
end

describe "resource(@checklist_type)" do 
  describe "a successful DELETE", :given => "a checklist_type exists" do
     before(:each) do
       @response = request(resource(ChecklistType.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:checklist_types))
     end

   end
end

describe "resource(:checklist_types, :new)" do
  before(:each) do
    @response = request(resource(:checklist_types, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@checklist_type, :edit)", :given => "a checklist_type exists" do
  before(:each) do
    @response = request(resource(ChecklistType.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@checklist_type)", :given => "a checklist_type exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(ChecklistType.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @checklist_type = ChecklistType.first
      @response = request(resource(@checklist_type), :method => "PUT", 
        :params => { :checklist_type => {:id => @checklist_type.id} })
    end
  
    it "redirect to the checklist_type show action" do
      @response.should redirect_to(resource(@checklist_type))
    end
  end
  
end

