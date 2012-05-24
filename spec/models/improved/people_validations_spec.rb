require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

class PeopleValidationsImpl
  include PeopleValidations

  attr_reader :client_dob

  def initialize(date_of_birth)
    @client_dob = date_of_birth
  end

end

describe PeopleValidations do

  before(:all) do
    @baccha_dob = Date.parse('2012-01-01')
    @baccha = PeopleValidationsImpl.new(@baccha_dob)
    #@jawaan = PeopleValidationsImpl.new(Date.new('1992-01-01'))
    #@buddha = PeopleValidationsImpl.new(Date.new('1947-01-01'))
  end

  it "should calculate the person age as expected" do

    @baccha.person_age.should == (Date.today.year - @baccha_dob.year)

  end

end
