require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/bank_branches" do
  before(:each) do
    @response = request("/bank_branches")
  end
end