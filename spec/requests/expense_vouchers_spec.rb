require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a expense_voucher exists" do
  ExpenseVoucher.all.destroy!
  request(resource(:expense_vouchers), :method => "POST", 
    :params => { :expense_voucher => { :id => nil }})
end

describe "resource(:expense_vouchers)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:expense_vouchers))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of expense_vouchers" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a expense_voucher exists" do
    before(:each) do
      @response = request(resource(:expense_vouchers))
    end
    
    it "has a list of expense_vouchers" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      ExpenseVoucher.all.destroy!
      @response = request(resource(:expense_vouchers), :method => "POST", 
        :params => { :expense_voucher => { :id => nil }})
    end
    
    it "redirects to resource(:expense_vouchers)" do
      @response.should redirect_to(resource(ExpenseVoucher.first), :message => {:notice => "expense_voucher was successfully created"})
    end
    
  end
end

describe "resource(@expense_voucher)" do 
  describe "a successful DELETE", :given => "a expense_voucher exists" do
     before(:each) do
       @response = request(resource(ExpenseVoucher.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:expense_vouchers))
     end

   end
end

describe "resource(:expense_vouchers, :new)" do
  before(:each) do
    @response = request(resource(:expense_vouchers, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@expense_voucher, :edit)", :given => "a expense_voucher exists" do
  before(:each) do
    @response = request(resource(ExpenseVoucher.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@expense_voucher)", :given => "a expense_voucher exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(ExpenseVoucher.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @expense_voucher = ExpenseVoucher.first
      @response = request(resource(@expense_voucher), :method => "PUT", 
        :params => { :expense_voucher => {:id => @expense_voucher.id} })
    end
  
    it "redirect to the expense_voucher show action" do
      @response.should redirect_to(resource(@expense_voucher))
    end
  end
  
end

