require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a guarantor exists" do
  Guarantor.all.destroy!
  request(resource(:guarantors), :method => "POST", 
    :params => { :guarantor => { :id => nil }})
end

describe "resource(:guarantors)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:guarantors))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of guarantors" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a guarantor exists" do
    before(:each) do
      @response = request(resource(:guarantors))
    end
    
    it "has a list of guarantors" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Guarantor.all.destroy!
      @response = request(resource(:guarantors), :method => "POST", 
        :params => { :guarantor => { :id => nil }})
    end
    
    it "redirects to resource(:guarantors)" do
      @response.should redirect_to(resource(Guarantor.first), :message => {:notice => "guarantor was successfully created"})
    end
    
  end
end

describe "resource(@guarantor)" do 
  describe "a successful DELETE", :given => "a guarantor exists" do
     before(:each) do
       @response = request(resource(Guarantor.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:guarantors))
     end

   end
end

describe "resource(:guarantors, :new)" do
  before(:each) do
    @response = request(resource(:guarantors, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@guarantor, :edit)", :given => "a guarantor exists" do
  before(:each) do
    @response = request(resource(Guarantor.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@guarantor)", :given => "a guarantor exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Guarantor.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @guarantor = Guarantor.first
      @response = request(resource(@guarantor), :method => "PUT", 
        :params => { :guarantor => {:id => @guarantor.id} })
    end
  
    it "redirect to the guarantor show action" do
      @response.should redirect_to(resource(@guarantor))
    end
  end
  
end

