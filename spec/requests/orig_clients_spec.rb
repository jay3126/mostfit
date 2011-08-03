require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/orig_clients" do
  before(:each) do
    @response = request("/orig_clients")
  end
end