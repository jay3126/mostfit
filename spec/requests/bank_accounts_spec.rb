require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/bank_accounts" do
  before(:each) do
    @response = request("/bank_accounts")
  end
end