require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a response exists" do
  Response.all.destroy!
  request(resource(:responses), :method => "POST", 
    :params => { :response => { :id => nil }})
end

describe "resource(:responses)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:responses))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of responses" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a response exists" do
    before(:each) do
      @response = request(resource(:responses))
    end
    
    it "has a list of responses" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Response.all.destroy!
      @response = request(resource(:responses), :method => "POST", 
        :params => { :response => { :id => nil }})
    end
    
    it "redirects to resource(:responses)" do
      @response.should redirect_to(resource(Response.first), :message => {:notice => "response was successfully created"})
    end
    
  end
end

describe "resource(@response)" do 
  describe "a successful DELETE", :given => "a response exists" do
     before(:each) do
       @response = request(resource(Response.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:responses))
     end

   end
end

describe "resource(:responses, :new)" do
  before(:each) do
    @response = request(resource(:responses, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@response, :edit)", :given => "a response exists" do
  before(:each) do
    @response = request(resource(Response.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@response)", :given => "a response exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Response.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @response = Response.first
      @response = request(resource(@response), :method => "PUT", 
        :params => { :response => {:id => @response.id} })
    end
  
    it "redirect to the response show action" do
      @response.should redirect_to(resource(@response))
    end
  end
  
end

