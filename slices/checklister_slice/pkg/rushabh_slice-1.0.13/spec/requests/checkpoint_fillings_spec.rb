require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a checkpoint_filling exists" do
  CheckpointFilling.all.destroy!
  request(resource(:checkpoint_fillings), :method => "POST", 
    :params => { :checkpoint_filling => { :id => nil }})
end

describe "resource(:checkpoint_fillings)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:checkpoint_fillings))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of checkpoint_fillings" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a checkpoint_filling exists" do
    before(:each) do
      @response = request(resource(:checkpoint_fillings))
    end
    
    it "has a list of checkpoint_fillings" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      CheckpointFilling.all.destroy!
      @response = request(resource(:checkpoint_fillings), :method => "POST", 
        :params => { :checkpoint_filling => { :id => nil }})
    end
    
    it "redirects to resource(:checkpoint_fillings)" do
      @response.should redirect_to(resource(CheckpointFilling.first), :message => {:notice => "checkpoint_filling was successfully created"})
    end
    
  end
end

describe "resource(@checkpoint_filling)" do 
  describe "a successful DELETE", :given => "a checkpoint_filling exists" do
     before(:each) do
       @response = request(resource(CheckpointFilling.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:checkpoint_fillings))
     end

   end
end

describe "resource(:checkpoint_fillings, :new)" do
  before(:each) do
    @response = request(resource(:checkpoint_fillings, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@checkpoint_filling, :edit)", :given => "a checkpoint_filling exists" do
  before(:each) do
    @response = request(resource(CheckpointFilling.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@checkpoint_filling)", :given => "a checkpoint_filling exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(CheckpointFilling.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @checkpoint_filling = CheckpointFilling.first
      @response = request(resource(@checkpoint_filling), :method => "PUT", 
        :params => { :checkpoint_filling => {:id => @checkpoint_filling.id} })
    end
  
    it "redirect to the checkpoint_filling show action" do
      @response.should redirect_to(resource(@checkpoint_filling))
    end
  end
  
end

