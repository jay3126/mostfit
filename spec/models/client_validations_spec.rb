require File.join( File.dirname(__FILE__), '..', "spec_helper" )

class ValidatedClient
  include ClientValidations

  attr_reader :date_of_birth

  def initialize(dob_str)
    @date_of_birth = dob_str ? Date.parse(dob_str) : nil
  end
end

describe ValidatedClient do

  it "should allow a client by age if within the age limit" do
    ValidatedClient.new('1970-01-03').permissible_age_for_credit?.should == true
  end

  it "should disallow a client by age if older than the age limit" do
    ValidatedClient.new('1950-01-03').permissible_age_for_credit?.should == false
  end

  it "should disallow a client by age if younger than the age limit" do
    ValidatedClient.new('2000-01-03').permissible_age_for_credit?.should == false
  end

end

