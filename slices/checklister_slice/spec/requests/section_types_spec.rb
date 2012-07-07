require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a section_type exists" do
  SectionType.all.destroy!
  request(resource(:section_types), :method => "POST", 
    :params => { :section_type => { :id => nil }})
end

describe "resource(:section_types)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:section_types))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of section_types" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a section_type exists" do
    before(:each) do
      @response = request(resource(:section_types))
    end
    
    it "has a list of section_types" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      SectionType.all.destroy!
      @response = request(resource(:section_types), :method => "POST", 
        :params => { :section_type => { :id => nil }})
    end
    
    it "redirects to resource(:section_types)" do
      @response.should redirect_to(resource(SectionType.first), :message => {:notice => "section_type was successfully created"})
    end
    
  end
end

describe "resource(@section_type)" do 
  describe "a successful DELETE", :given => "a section_type exists" do
     before(:each) do
       @response = request(resource(SectionType.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:section_types))
     end

   end
end

describe "resource(:section_types, :new)" do
  before(:each) do
    @response = request(resource(:section_types, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@section_type, :edit)", :given => "a section_type exists" do
  before(:each) do
    @response = request(resource(SectionType.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@section_type)", :given => "a section_type exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(SectionType.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @section_type = SectionType.first
      @response = request(resource(@section_type), :method => "PUT", 
        :params => { :section_type => {:id => @section_type.id} })
    end
  
    it "redirect to the section_type show action" do
      @response.should redirect_to(resource(@section_type))
    end
  end
  
end

