require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a target_entity exists" do
  TargetEntity.all.destroy!
  request(resource(:target_entities), :method => "POST", 
    :params => { :target_entity => { :id => nil }})
end

describe "resource(:target_entities)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:target_entities))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of target_entities" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a target_entity exists" do
    before(:each) do
      @response = request(resource(:target_entities))
    end
    
    it "has a list of target_entities" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      TargetEntity.all.destroy!
      @response = request(resource(:target_entities), :method => "POST", 
        :params => { :target_entity => { :id => nil }})
    end
    
    it "redirects to resource(:target_entities)" do
      @response.should redirect_to(resource(TargetEntity.first), :message => {:notice => "target_entity was successfully created"})
    end
    
  end
end

describe "resource(@target_entity)" do 
  describe "a successful DELETE", :given => "a target_entity exists" do
     before(:each) do
       @response = request(resource(TargetEntity.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:target_entities))
     end

   end
end

describe "resource(:target_entities, :new)" do
  before(:each) do
    @response = request(resource(:target_entities, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@target_entity, :edit)", :given => "a target_entity exists" do
  before(:each) do
    @response = request(resource(TargetEntity.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@target_entity)", :given => "a target_entity exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(TargetEntity.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @target_entity = TargetEntity.first
      @response = request(resource(@target_entity), :method => "PUT", 
        :params => { :target_entity => {:id => @target_entity.id} })
    end
  
    it "redirect to the target_entity show action" do
      @response.should redirect_to(resource(@target_entity))
    end
  end
  
end

