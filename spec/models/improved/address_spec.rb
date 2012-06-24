require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe Address do

  before(:all) do
    @some_location = Factory(:biz_location)
  end

  it "should set the address and address text as expected" do
    line_1 = "12, Moledina Road"
    line_2 = "Next to Pulse Dance Studio"
    address_state = "Maharashtra"
    address_town  = "Pune"
    address_pin_code = "411001"
    full_address_text = "12, Moledina Road, Next to Pulse Dance Studio, Pune, Maharashtra, Pin Code: 411001"
    
    state_obj = AddressState.create(:name => address_state)
    town_obj = AddressTown.create(:name => address_town, :address_state => state_obj)
    pin_code_obj = AddressPinCode.create(:pin_code => address_pin_code, :address_town => town_obj)
    address_obj = Address.create(
        :address_line_1 => line_1, 
        :address_line_2 => line_2, 
        :address_town => town_obj, 
        :address_state => state_obj,
        :address_pin_code => pin_code_obj
        )
    @some_location.address = address_obj; @some_location.save
    @some_location.address_text.should == full_address_text
  end

  it "should return the list of pin codes permitted at a location as expected" do
    line_1 = "12, Moledina Road"
    line_2 = "Next to Pulse Dance Studio"
    address_state = "Maharashtra"
    address_town  = "Pune"
    address_pin_code = "411001"
    full_address_text = "12, Moledina Road, Next to Pulse Dance Studio, Pune, Maharashtra, Pin Code: 411001"
    
    state_obj = AddressState.create(:name => address_state)
    town_obj = AddressTown.create(:name => address_town, :address_state => state_obj)
    pin_code_obj = AddressPinCode.create(:pin_code => address_pin_code, :address_town => town_obj)
    address_obj = Address.create(
        :address_line_1 => line_1, 
        :address_line_2 => line_2, 
        :address_town => town_obj, 
        :address_state => state_obj,
        :address_pin_code => pin_code_obj
        )
    @some_location.address = address_obj; @some_location.save

    a_pin_code = AddressPinCode.new(:pin_code => "411013", :address_town => town_obj)
    b_pin_code = AddressPinCode.new(:pin_code => "411028", :address_town => town_obj)
    @some_location.permitted_pin_codes << a_pin_code
    @some_location.permitted_pin_codes << b_pin_code
    @some_location.save

    all_pin_codes = @some_location.all_pin_codes
    all_pin_codes.length.should == 3
    all_pin_codes.include?(a_pin_code).should be_true
    all_pin_codes.include?(b_pin_code).should be_true
    all_pin_codes.include?(pin_code_obj).should be_true
  end

end