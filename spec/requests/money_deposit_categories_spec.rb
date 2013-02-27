require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/money_deposit_categories" do
  before(:each) do
    @response = request("/money_deposit_categories")
  end
end