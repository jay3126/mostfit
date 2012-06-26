require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe ClientAdministration do

  before(:each) do
    @location_creation_date = Date.parse('2012-01-01')
    location_attributes = Factory.attributes_for(:biz_location)
    @l1 = Factory.create(:biz_location, location_attributes.merge(:creation_date => @location_creation_date))
    @l2 = Factory.create(:biz_location, location_attributes.merge(:creation_date => @location_creation_date))
    @l3 = Factory.create(:biz_location, location_attributes.merge(:creation_date => @location_creation_date))
    @l4 = Factory.create(:biz_location, location_attributes.merge(:creation_date => @location_creation_date))
    @all_locations = [@l1, @l2, @l3, @l4]

    @client_joining_date = Date.parse('2012-02-01')
    client_attributes = Factory.attributes_for(:client)
    @client_1 = Factory.create(:client, client_attributes.merge(:date_joined => @client_joining_date))
    @client_2 = Factory.create(:client, client_attributes.merge(:date_joined => @client_joining_date))
    @client_3 = Factory.create(:client, client_attributes.merge(:date_joined => @client_joining_date))

    @performed_by = Factory(:staff_member).id
    @recorded_by  = Factory(:user)
    @recorded_by_id = @recorded_by.id

    @choice_facade = FacadeFactory.instance.get_instance(FacadeFactory::CHOICE_FACADE, @recorded_by)
  end

  it "should disallow a new administration on the same date as an existing administration" do
    effective_on = Date.parse('2012-04-01')
    ClientAdministration.assign(@l1, @l2, @client_1, @performed_by, @recorded_by_id, effective_on)
    lambda{ ClientAdministration.assign(@l1, @l2, @client_1, @performed_by, @recorded_by_id, effective_on) }.should raise_error
  end

  it "should return the clients administered at a location on the expected dates" do
    first_date = Date.parse('2012-04-01')
    second_date = Date.parse('2012-04-12')

    ClientAdministration.get_clients_administered(@l1, first_date).should be_empty
    ClientAdministration.get_clients_registered(@l2, first_date).should be_empty

    ClientAdministration.assign(@l1, @l2, @client_1, @performed_by, @recorded_by_id, first_date)
    ClientAdministration.assign(@l1, @l2, @client_2, @performed_by, @recorded_by_id, first_date)

    (first_date...second_date).each { |date|
      administered_earlier = ClientAdministration.get_clients_administered(@l1.id, date)
      registered_earlier   = ClientAdministration.get_clients_registered(@l2.id, date)

      administered_earlier.length.should == 2
      administered_earlier.include?(@client_1).should be_true
      administered_earlier.include?(@client_2).should be_true

      registered_earlier.length.should == 2
      registered_earlier.include?(@client_1).should be_true
      registered_earlier.include?(@client_2).should be_true

      administered_later = ClientAdministration.get_clients_administered(@l3.id, date)
      registered_later   = ClientAdministration.get_clients_registered(@l4.id, date)

      administered_later.should be_empty
      registered_later.should be_empty
    }

    ClientAdministration.assign(@l3, @l4, @client_1, @performed_by, @recorded_by_id, second_date)
    ClientAdministration.assign(@l3, @l4, @client_2, @performed_by, @recorded_by_id, second_date)

    (second_date..(second_date + 3)).each { |date|
      administered_later = ClientAdministration.get_clients_administered(@l3.id, date)
      registered_later   = ClientAdministration.get_clients_registered(@l4.id, date)

      administered_later.length.should == 2
      administered_later.include?(@client_1).should be_true
      administered_later.include?(@client_2).should be_true

      registered_later.length.should == 2
      registered_later.include?(@client_1).should be_true
      registered_later.include?(@client_2).should be_true

      administered_earlier = ClientAdministration.get_clients_administered(@l1.id, date)
      registered_earlier   = ClientAdministration.get_clients_registered(@l2.id, date)

      administered_earlier.should be_empty
      registered_earlier.should be_empty
    }
  end

  it "should return the series of locations for a client as per the administration changes due to movement" do
    first_date = Date.parse('2012-04-01')
    second_date = Date.parse('2012-04-12')

    (first_date..(second_date + 1)).each { |date|
      ClientAdministration.get_administered_at(@client_1, date).should be_nil
      ClientAdministration.get_registered_at(@client_1, date).should be_nil
    }

    ClientAdministration.assign(@l1, @l2, @client_1, @performed_by, @recorded_by_id, first_date)
    ClientAdministration.assign(@l3, @l4, @client_1, @performed_by, @recorded_by_id, second_date)

    ClientAdministration.get_administered_at(@client_1, (first_date - 1)).should be_nil
    ClientAdministration.get_registered_at(@client_1, (first_date - 1)).should be_nil

    (first_date...second_date).each { |date|
      ClientAdministration.get_administered_at(@client_1, date).should == @l1
      ClientAdministration.get_registered_at(@client_1, date).should == @l2
    }

    ClientAdministration.get_administered_at(@client_1, second_date).should == @l3
    ClientAdministration.get_registered_at(@client_1, second_date).should == @l4

    ClientAdministration.get_administered_at(@client_1, (second_date + 1)).should == @l3
    ClientAdministration.get_registered_at(@client_1, (second_date + 1)).should == @l4
  end

  it "should indicate that a location does not have any clients administered when none have been assigned" do
    (ClientAdministration.get_clients_administered(@l1.id, Date.today)).should be_empty
  end

  it "should indicate that a location does not have any clients registered when none have been assigned" do
    (ClientAdministration.get_clients_administered(@l2.id, Date.today)).should be_empty
  end

  it "should indicate the locations administered and registered for a client at the time of creation the same as the origin locations"

  it "should disallow administration before the date that either the client has joined or the locations are created" do
    lambda {ClientAdministration.assign(@l1, @l2, @client_1, @performed_by, @recorded_by_id, (@client_joining_date - 1))}.should raise_error
    lambda {ClientAdministration.assign(@l1, @l2, @client_1, @performed_by, @recorded_by_id, (@location_creation_date - 1))}.should raise_error
  end

  it "should disallow changing the administration when the client is inactive" do
    @client_1.update(:active => false)
    @client_1.active.should be_false
    lambda {ClientAdministration.assign(@l1, @l2, @client_1, @performed_by, @recorded_by_id, Date.today)}.should raise_error
  end
  
end
