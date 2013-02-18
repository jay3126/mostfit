require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/surprise_visit_center" do
  before(:each) do
    @response = request("/surprise_visit_center")
  end
end