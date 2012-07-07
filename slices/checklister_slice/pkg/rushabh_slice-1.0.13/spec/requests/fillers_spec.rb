require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a filler exists" do
  Filler.all.destroy!
  request(resource(:fillers), :method => "POST", 
    :params => { :filler => { :id => nil }})
end

describe "resource(:fillers)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:fillers))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of fillers" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a filler exists" do
    before(:each) do
      @response = request(resource(:fillers))
    end
    
    it "has a list of fillers" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Filler.all.destroy!
      @response = request(resource(:fillers), :method => "POST", 
        :params => { :filler => { :id => nil }})
    end
    
    it "redirects to resource(:fillers)" do
      @response.should redirect_to(resource(Filler.first), :message => {:notice => "filler was successfully created"})
    end
    
  end
end

describe "resource(@filler)" do 
  describe "a successful DELETE", :given => "a filler exists" do
     before(:each) do
       @response = request(resource(Filler.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:fillers))
     end

   end
end

describe "resource(:fillers, :new)" do
  before(:each) do
    @response = request(resource(:fillers, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@filler, :edit)", :given => "a filler exists" do
  before(:each) do
    @response = request(resource(Filler.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@filler)", :given => "a filler exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Filler.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @filler = Filler.first
      @response = request(resource(@filler), :method => "PUT", 
        :params => { :filler => {:id => @filler.id} })
    end
  
    it "redirect to the filler show action" do
      @response.should redirect_to(resource(@filler))
    end
  end
  
end

