require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a surprise_center_visit exists" do
  SurpriseCenterVisit.all.destroy!
  request(resource(:surprise_center_visits), :method => "POST", 
    :params => { :surprise_center_visit => { :id => nil }})
end

describe "resource(:surprise_center_visits)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:surprise_center_visits))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of surprise_center_visits" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a surprise_center_visit exists" do
    before(:each) do
      @response = request(resource(:surprise_center_visits))
    end
    
    it "has a list of surprise_center_visits" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      SurpriseCenterVisit.all.destroy!
      @response = request(resource(:surprise_center_visits), :method => "POST", 
        :params => { :surprise_center_visit => { :id => nil }})
    end
    
    it "redirects to resource(:surprise_center_visits)" do
      @response.should redirect_to(resource(SurpriseCenterVisit.first), :message => {:notice => "surprise_center_visit was successfully created"})
    end
    
  end
end

describe "resource(@surprise_center_visit)" do 
  describe "a successful DELETE", :given => "a surprise_center_visit exists" do
     before(:each) do
       @response = request(resource(SurpriseCenterVisit.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:surprise_center_visits))
     end

   end
end

describe "resource(:surprise_center_visits, :new)" do
  before(:each) do
    @response = request(resource(:surprise_center_visits, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@surprise_center_visit, :edit)", :given => "a surprise_center_visit exists" do
  before(:each) do
    @response = request(resource(SurpriseCenterVisit.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@surprise_center_visit)", :given => "a surprise_center_visit exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(SurpriseCenterVisit.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @surprise_center_visit = SurpriseCenterVisit.first
      @response = request(resource(@surprise_center_visit), :method => "PUT", 
        :params => { :surprise_center_visit => {:id => @surprise_center_visit.id} })
    end
  
    it "redirect to the surprise_center_visit show action" do
      @response.should redirect_to(resource(@surprise_center_visit))
    end
  end
  
end

