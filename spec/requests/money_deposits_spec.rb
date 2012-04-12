require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/money_deposits" do
  before(:each) do
    @response = request("/money_deposits")
  end
end