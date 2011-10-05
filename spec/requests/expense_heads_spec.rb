require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a expense_head exists" do
  ExpenseHead.all.destroy!
  request(resource(:expense_heads), :method => "POST", 
    :params => { :expense_head => { :id => nil }})
end

describe "resource(:expense_heads)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:expense_heads))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of expense_heads" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a expense_head exists" do
    before(:each) do
      @response = request(resource(:expense_heads))
    end
    
    it "has a list of expense_heads" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      ExpenseHead.all.destroy!
      @response = request(resource(:expense_heads), :method => "POST", 
        :params => { :expense_head => { :id => nil }})
    end
    
    it "redirects to resource(:expense_heads)" do
      @response.should redirect_to(resource(ExpenseHead.first), :message => {:notice => "expense_head was successfully created"})
    end
    
  end
end

describe "resource(@expense_head)" do 
  describe "a successful DELETE", :given => "a expense_head exists" do
     before(:each) do
       @response = request(resource(ExpenseHead.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:expense_heads))
     end

   end
end

describe "resource(:expense_heads, :new)" do
  before(:each) do
    @response = request(resource(:expense_heads, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@expense_head, :edit)", :given => "a expense_head exists" do
  before(:each) do
    @response = request(resource(ExpenseHead.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@expense_head)", :given => "a expense_head exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(ExpenseHead.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @expense_head = ExpenseHead.first
      @response = request(resource(@expense_head), :method => "PUT", 
        :params => { :expense_head => {:id => @expense_head.id} })
    end
  
    it "redirect to the expense_head show action" do
      @response.should redirect_to(resource(@expense_head))
    end
  end
  
end

