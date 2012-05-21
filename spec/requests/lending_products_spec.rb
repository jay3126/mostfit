require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/lending_products" do
  before(:each) do
    @response = request("/lending_products")
  end
end