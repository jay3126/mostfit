require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a processaudit exists" do
  Processaudit.all.destroy!
  request(resource(:processaudits), :method => "POST", 
    :params => { :processaudit => { :id => nil }})
end

describe "resource(:processaudits)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:processaudits))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of processaudits" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a processaudit exists" do
    before(:each) do
      @response = request(resource(:processaudits))
    end
    
    it "has a list of processaudits" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Processaudit.all.destroy!
      @response = request(resource(:processaudits), :method => "POST", 
        :params => { :processaudit => { :id => nil }})
    end
    
    it "redirects to resource(:processaudits)" do
      @response.should redirect_to(resource(Processaudit.first), :message => {:notice => "processaudit was successfully created"})
    end
    
  end
end

describe "resource(@processaudit)" do 
  describe "a successful DELETE", :given => "a processaudit exists" do
     before(:each) do
       @response = request(resource(Processaudit.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:processaudits))
     end

   end
end

describe "resource(:processaudits, :new)" do
  before(:each) do
    @response = request(resource(:processaudits, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@processaudit, :edit)", :given => "a processaudit exists" do
  before(:each) do
    @response = request(resource(Processaudit.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@processaudit)", :given => "a processaudit exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Processaudit.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @processaudit = Processaudit.first
      @response = request(resource(@processaudit), :method => "PUT", 
        :params => { :processaudit => {:id => @processaudit.id} })
    end
  
    it "redirect to the processaudit show action" do
      @response.should redirect_to(resource(@processaudit))
    end
  end
  
end

