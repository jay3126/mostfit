require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a radiobuttonpoint_filling exists" do
  RadiobuttonpointFilling.all.destroy!
  request(resource(:radiobuttonpoint_fillings), :method => "POST", 
    :params => { :radiobuttonpoint_filling => { :id => nil }})
end

describe "resource(:radiobuttonpoint_fillings)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:radiobuttonpoint_fillings))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of radiobuttonpoint_fillings" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a radiobuttonpoint_filling exists" do
    before(:each) do
      @response = request(resource(:radiobuttonpoint_fillings))
    end
    
    it "has a list of radiobuttonpoint_fillings" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      RadiobuttonpointFilling.all.destroy!
      @response = request(resource(:radiobuttonpoint_fillings), :method => "POST", 
        :params => { :radiobuttonpoint_filling => { :id => nil }})
    end
    
    it "redirects to resource(:radiobuttonpoint_fillings)" do
      @response.should redirect_to(resource(RadiobuttonpointFilling.first), :message => {:notice => "radiobuttonpoint_filling was successfully created"})
    end
    
  end
end

describe "resource(@radiobuttonpoint_filling)" do 
  describe "a successful DELETE", :given => "a radiobuttonpoint_filling exists" do
     before(:each) do
       @response = request(resource(RadiobuttonpointFilling.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:radiobuttonpoint_fillings))
     end

   end
end

describe "resource(:radiobuttonpoint_fillings, :new)" do
  before(:each) do
    @response = request(resource(:radiobuttonpoint_fillings, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@radiobuttonpoint_filling, :edit)", :given => "a radiobuttonpoint_filling exists" do
  before(:each) do
    @response = request(resource(RadiobuttonpointFilling.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@radiobuttonpoint_filling)", :given => "a radiobuttonpoint_filling exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(RadiobuttonpointFilling.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @radiobuttonpoint_filling = RadiobuttonpointFilling.first
      @response = request(resource(@radiobuttonpoint_filling), :method => "PUT", 
        :params => { :radiobuttonpoint_filling => {:id => @radiobuttonpoint_filling.id} })
    end
  
    it "redirect to the radiobuttonpoint_filling show action" do
      @response.should redirect_to(resource(@radiobuttonpoint_filling))
    end
  end
  
end

