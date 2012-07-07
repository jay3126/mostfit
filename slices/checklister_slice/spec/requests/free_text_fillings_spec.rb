require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a free_text_filling exists" do
  FreeTextFilling.all.destroy!
  request(resource(:free_text_fillings), :method => "POST", 
    :params => { :free_text_filling => { :id => nil }})
end

describe "resource(:free_text_fillings)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:free_text_fillings))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of free_text_fillings" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a free_text_filling exists" do
    before(:each) do
      @response = request(resource(:free_text_fillings))
    end
    
    it "has a list of free_text_fillings" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      FreeTextFilling.all.destroy!
      @response = request(resource(:free_text_fillings), :method => "POST", 
        :params => { :free_text_filling => { :id => nil }})
    end
    
    it "redirects to resource(:free_text_fillings)" do
      @response.should redirect_to(resource(FreeTextFilling.first), :message => {:notice => "free_text_filling was successfully created"})
    end
    
  end
end

describe "resource(@free_text_filling)" do 
  describe "a successful DELETE", :given => "a free_text_filling exists" do
     before(:each) do
       @response = request(resource(FreeTextFilling.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:free_text_fillings))
     end

   end
end

describe "resource(:free_text_fillings, :new)" do
  before(:each) do
    @response = request(resource(:free_text_fillings, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@free_text_filling, :edit)", :given => "a free_text_filling exists" do
  before(:each) do
    @response = request(resource(FreeTextFilling.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@free_text_filling)", :given => "a free_text_filling exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(FreeTextFilling.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @free_text_filling = FreeTextFilling.first
      @response = request(resource(@free_text_filling), :method => "PUT", 
        :params => { :free_text_filling => {:id => @free_text_filling.id} })
    end
  
    it "redirect to the free_text_filling show action" do
      @response.should redirect_to(resource(@free_text_filling))
    end
  end
  
end

