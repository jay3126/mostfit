require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a surprise_visit_center exists" do
  SurpriseVisitCenter.all.destroy!
  request(resource(:surprise_visit_centers), :method => "POST", 
    :params => { :surprise_visit_center => { :id => nil }})
end

describe "resource(:surprise_visit_centers)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:surprise_visit_centers))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of surprise_visit_centers" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a surprise_visit_center exists" do
    before(:each) do
      @response = request(resource(:surprise_visit_centers))
    end
    
    it "has a list of surprise_visit_centers" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      SurpriseVisitCenter.all.destroy!
      @response = request(resource(:surprise_visit_centers), :method => "POST", 
        :params => { :surprise_visit_center => { :id => nil }})
    end
    
    it "redirects to resource(:surprise_visit_centers)" do
      @response.should redirect_to(resource(SurpriseVisitCenter.first), :message => {:notice => "surprise_visit_center was successfully created"})
    end
    
  end
end

describe "resource(@surprise_visit_center)" do 
  describe "a successful DELETE", :given => "a surprise_visit_center exists" do
     before(:each) do
       @response = request(resource(SurpriseVisitCenter.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:surprise_visit_centers))
     end

   end
end

describe "resource(:surprise_visit_centers, :new)" do
  before(:each) do
    @response = request(resource(:surprise_visit_centers, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@surprise_visit_center, :edit)", :given => "a surprise_visit_center exists" do
  before(:each) do
    @response = request(resource(SurpriseVisitCenter.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@surprise_visit_center)", :given => "a surprise_visit_center exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(SurpriseVisitCenter.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @surprise_visit_center = SurpriseVisitCenter.first
      @response = request(resource(@surprise_visit_center), :method => "PUT", 
        :params => { :surprise_visit_center => {:id => @surprise_visit_center.id} })
    end
  
    it "redirect to the surprise_visit_center show action" do
      @response.should redirect_to(resource(@surprise_visit_center))
    end
  end
  
end

