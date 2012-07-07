require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a checklist exists" do
  Checklist.all.destroy!
  request(resource(:checklists), :method => "POST", 
    :params => { :checklist => { :id => nil }})
end

describe "resource(:checklists)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:checklists))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of checklists" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a checklist exists" do
    before(:each) do
      @response = request(resource(:checklists))
    end
    
    it "has a list of checklists" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Checklist.all.destroy!
      @response = request(resource(:checklists), :method => "POST", 
        :params => { :checklist => { :id => nil }})
    end
    
    it "redirects to resource(:checklists)" do
      @response.should redirect_to(resource(Checklist.first), :message => {:notice => "checklist was successfully created"})
    end
    
  end
end

describe "resource(@checklist)" do 
  describe "a successful DELETE", :given => "a checklist exists" do
     before(:each) do
       @response = request(resource(Checklist.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:checklists))
     end

   end
end

describe "resource(:checklists, :new)" do
  before(:each) do
    @response = request(resource(:checklists, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@checklist, :edit)", :given => "a checklist exists" do
  before(:each) do
    @response = request(resource(Checklist.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@checklist)", :given => "a checklist exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Checklist.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @checklist = Checklist.first
      @response = request(resource(@checklist), :method => "PUT", 
        :params => { :checklist => {:id => @checklist.id} })
    end
  
    it "redirect to the checklist show action" do
      @response.should redirect_to(resource(@checklist))
    end
  end
  
end

