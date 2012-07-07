require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a radiobuttonpoint exists" do
  Radiobuttonpoint.all.destroy!
  request(resource(:radiobuttonpoints), :method => "POST", 
    :params => { :radiobuttonpoint => { :id => nil }})
end

describe "resource(:radiobuttonpoints)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:radiobuttonpoints))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of radiobuttonpoints" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a radiobuttonpoint exists" do
    before(:each) do
      @response = request(resource(:radiobuttonpoints))
    end
    
    it "has a list of radiobuttonpoints" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Radiobuttonpoint.all.destroy!
      @response = request(resource(:radiobuttonpoints), :method => "POST", 
        :params => { :radiobuttonpoint => { :id => nil }})
    end
    
    it "redirects to resource(:radiobuttonpoints)" do
      @response.should redirect_to(resource(Radiobuttonpoint.first), :message => {:notice => "radiobuttonpoint was successfully created"})
    end
    
  end
end

describe "resource(@radiobuttonpoint)" do 
  describe "a successful DELETE", :given => "a radiobuttonpoint exists" do
     before(:each) do
       @response = request(resource(Radiobuttonpoint.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:radiobuttonpoints))
     end

   end
end

describe "resource(:radiobuttonpoints, :new)" do
  before(:each) do
    @response = request(resource(:radiobuttonpoints, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@radiobuttonpoint, :edit)", :given => "a radiobuttonpoint exists" do
  before(:each) do
    @response = request(resource(Radiobuttonpoint.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@radiobuttonpoint)", :given => "a radiobuttonpoint exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Radiobuttonpoint.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @radiobuttonpoint = Radiobuttonpoint.first
      @response = request(resource(@radiobuttonpoint), :method => "PUT", 
        :params => { :radiobuttonpoint => {:id => @radiobuttonpoint.id} })
    end
  
    it "redirect to the radiobuttonpoint show action" do
      @response.should redirect_to(resource(@radiobuttonpoint))
    end
  end
  
end

