require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a psl_sub_category exists" do
  PslSubCategory.all.destroy!
  request(resource(:psl_sub_categories), :method => "POST", 
    :params => { :psl_sub_category => { :id => nil }})
end

describe "resource(:psl_sub_categories)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:psl_sub_categories))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of psl_sub_categories" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a psl_sub_category exists" do
    before(:each) do
      @response = request(resource(:psl_sub_categories))
    end
    
    it "has a list of psl_sub_categories" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      PslSubCategory.all.destroy!
      @response = request(resource(:psl_sub_categories), :method => "POST", 
        :params => { :psl_sub_category => { :id => nil }})
    end
    
    it "redirects to resource(:psl_sub_categories)" do
      @response.should redirect_to(resource(PslSubCategory.first), :message => {:notice => "psl_sub_category was successfully created"})
    end
    
  end
end

describe "resource(@psl_sub_category)" do 
  describe "a successful DELETE", :given => "a psl_sub_category exists" do
     before(:each) do
       @response = request(resource(PslSubCategory.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:psl_sub_categories))
     end

   end
end

describe "resource(:psl_sub_categories, :new)" do
  before(:each) do
    @response = request(resource(:psl_sub_categories, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@psl_sub_category, :edit)", :given => "a psl_sub_category exists" do
  before(:each) do
    @response = request(resource(PslSubCategory.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@psl_sub_category)", :given => "a psl_sub_category exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(PslSubCategory.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @psl_sub_category = PslSubCategory.first
      @response = request(resource(@psl_sub_category), :method => "PUT", 
        :params => { :psl_sub_category => {:id => @psl_sub_category.id} })
    end
  
    it "redirect to the psl_sub_category show action" do
      @response.should redirect_to(resource(@psl_sub_category))
    end
  end
  
end

