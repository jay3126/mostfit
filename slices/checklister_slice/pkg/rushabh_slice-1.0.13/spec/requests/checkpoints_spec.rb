require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a checkpoint exists" do
  Checkpoint.all.destroy!
  request(resource(:checkpoints), :method => "POST", 
    :params => { :checkpoint => { :id => nil }})
end

describe "resource(:checkpoints)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:checkpoints))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of checkpoints" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a checkpoint exists" do
    before(:each) do
      @response = request(resource(:checkpoints))
    end
    
    it "has a list of checkpoints" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Checkpoint.all.destroy!
      @response = request(resource(:checkpoints), :method => "POST", 
        :params => { :checkpoint => { :id => nil }})
    end
    
    it "redirects to resource(:checkpoints)" do
      @response.should redirect_to(resource(Checkpoint.first), :message => {:notice => "checkpoint was successfully created"})
    end
    
  end
end

describe "resource(@checkpoint)" do 
  describe "a successful DELETE", :given => "a checkpoint exists" do
     before(:each) do
       @response = request(resource(Checkpoint.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:checkpoints))
     end

   end
end

describe "resource(:checkpoints, :new)" do
  before(:each) do
    @response = request(resource(:checkpoints, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@checkpoint, :edit)", :given => "a checkpoint exists" do
  before(:each) do
    @response = request(resource(Checkpoint.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@checkpoint)", :given => "a checkpoint exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Checkpoint.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @checkpoint = Checkpoint.first
      @response = request(resource(@checkpoint), :method => "PUT", 
        :params => { :checkpoint => {:id => @checkpoint.id} })
    end
  
    it "redirect to the checkpoint show action" do
      @response.should redirect_to(resource(@checkpoint))
    end
  end
  
end

