require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/bank" do
  before(:each) do
    @response = request("/bank")
  end
end