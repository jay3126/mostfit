require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a section exists" do
  Section.all.destroy!
  request(resource(:sections), :method => "POST", 
    :params => { :section => { :id => nil }})
end

describe "resource(:sections)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:sections))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of sections" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a section exists" do
    before(:each) do
      @response = request(resource(:sections))
    end
    
    it "has a list of sections" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Section.all.destroy!
      @response = request(resource(:sections), :method => "POST", 
        :params => { :section => { :id => nil }})
    end
    
    it "redirects to resource(:sections)" do
      @response.should redirect_to(resource(Section.first), :message => {:notice => "section was successfully created"})
    end
    
  end
end

describe "resource(@section)" do 
  describe "a successful DELETE", :given => "a section exists" do
     before(:each) do
       @response = request(resource(Section.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:sections))
     end

   end
end

describe "resource(:sections, :new)" do
  before(:each) do
    @response = request(resource(:sections, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@section, :edit)", :given => "a section exists" do
  before(:each) do
    @response = request(resource(Section.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@section)", :given => "a section exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Section.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @section = Section.first
      @response = request(resource(@section), :method => "PUT", 
        :params => { :section => {:id => @section.id} })
    end
  
    it "redirect to the section show action" do
      @response.should redirect_to(resource(@section))
    end
  end
  
end

