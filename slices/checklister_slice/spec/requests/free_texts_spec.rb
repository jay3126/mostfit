require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a free_text exists" do
  FreeText.all.destroy!
  request(resource(:free_texts), :method => "POST", 
    :params => { :free_text => { :id => nil }})
end

describe "resource(:free_texts)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:free_texts))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of free_texts" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a free_text exists" do
    before(:each) do
      @response = request(resource(:free_texts))
    end
    
    it "has a list of free_texts" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      FreeText.all.destroy!
      @response = request(resource(:free_texts), :method => "POST", 
        :params => { :free_text => { :id => nil }})
    end
    
    it "redirects to resource(:free_texts)" do
      @response.should redirect_to(resource(FreeText.first), :message => {:notice => "free_text was successfully created"})
    end
    
  end
end

describe "resource(@free_text)" do 
  describe "a successful DELETE", :given => "a free_text exists" do
     before(:each) do
       @response = request(resource(FreeText.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:free_texts))
     end

   end
end

describe "resource(:free_texts, :new)" do
  before(:each) do
    @response = request(resource(:free_texts, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@free_text, :edit)", :given => "a free_text exists" do
  before(:each) do
    @response = request(resource(FreeText.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@free_text)", :given => "a free_text exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(FreeText.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @free_text = FreeText.first
      @response = request(resource(@free_text), :method => "PUT", 
        :params => { :free_text => {:id => @free_text.id} })
    end
  
    it "redirect to the free_text show action" do
      @response.should redirect_to(resource(@free_text))
    end
  end
  
end

