require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a pachecklist exists" do
  Pachecklist.all.destroy!
  request(resource(:pachecklists), :method => "POST", 
    :params => { :pachecklist => { :id => nil }})
end

describe "resource(:pachecklists)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:pachecklists))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of pachecklists" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a pachecklist exists" do
    before(:each) do
      @response = request(resource(:pachecklists))
    end
    
    it "has a list of pachecklists" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Pachecklist.all.destroy!
      @response = request(resource(:pachecklists), :method => "POST", 
        :params => { :pachecklist => { :id => nil }})
    end
    
    it "redirects to resource(:pachecklists)" do
      @response.should redirect_to(resource(Pachecklist.first), :message => {:notice => "pachecklist was successfully created"})
    end
    
  end
end

describe "resource(@pachecklist)" do 
  describe "a successful DELETE", :given => "a pachecklist exists" do
     before(:each) do
       @response = request(resource(Pachecklist.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:pachecklists))
     end

   end
end

describe "resource(:pachecklists, :new)" do
  before(:each) do
    @response = request(resource(:pachecklists, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@pachecklist, :edit)", :given => "a pachecklist exists" do
  before(:each) do
    @response = request(resource(Pachecklist.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@pachecklist)", :given => "a pachecklist exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Pachecklist.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @pachecklist = Pachecklist.first
      @response = request(resource(@pachecklist), :method => "PUT", 
        :params => { :pachecklist => {:id => @pachecklist.id} })
    end
  
    it "redirect to the pachecklist show action" do
      @response.should redirect_to(resource(@pachecklist))
    end
  end
  
end

