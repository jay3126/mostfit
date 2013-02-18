require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a checklist_news exists" do
  Checklist.all.destroy!
  request(resource(:checklist_news), :method => "POST", 
    :params => { :checklist_news => { :id => nil }})
end

describe "resource(:checklist_news)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:checklist_news))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of checklist_news" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a checklist_news exists" do
    before(:each) do
      @response = request(resource(:checklist_news))
    end
    
    it "has a list of checklist_news" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Checklist.all.destroy!
      @response = request(resource(:checklist_news), :method => "POST", 
        :params => { :checklist_news => { :id => nil }})
    end
    
    it "redirects to resource(:checklist_news)" do
      @response.should redirect_to(resource(Checklist.first), :message => {:notice => "checklist_news was successfully created"})
    end
    
  end
end

describe "resource(@checklist_news)" do 
  describe "a successful DELETE", :given => "a checklist_news exists" do
     before(:each) do
       @response = request(resource(Checklist.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:checklist_news))
     end

   end
end

describe "resource(:checklist_news, :new)" do
  before(:each) do
    @response = request(resource(:checklist_news, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@checklist_news, :edit)", :given => "a checklist_news exists" do
  before(:each) do
    @response = request(resource(Checklist.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@checklist_news)", :given => "a checklist_news exists" do
  
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
      @checklist_news = Checklist.first
      @response = request(resource(@checklist_news), :method => "PUT", 
        :params => { :checklist_news => {:id => @checklist_news.id} })
    end
  
    it "redirect to the checklist_news show action" do
      @response.should redirect_to(resource(@checklist_news))
    end
  end
  
end

