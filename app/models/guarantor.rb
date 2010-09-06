
class Guarantor
  include DataMapper::Resource

  RELATIONS = ['Spouse', 'Father', 'Mother', 'Adult Son', 'Other']
  DOC = ['voter_id', 'driving_licence', 'pan_card', 'gp_certificate', 'ration_card', 'nrega_card', 'phone_bill','electricity_bill']
  property :id,   Serial
  property :name, String, :index => true
  property :father_name, String, :index => true
  property :date_of_birth, Date, :nullable => false, :default => Date.today
  property :address, String 
  property :relationship_to_client, Enum.send('[]',*RELATIONS),:default => '', :nullable => true, :lazy => true
  property :external_id_number, String, :index => true
  property :external_id_type, Enum.send('[]',*DOC), :default => '', :nullable => true, :lazy => true
 
  belongs_to :client
  validates_present :name
  validates_present :father_name
  validates_length :name,   :minimum => 3
  validates_length :father_name,   :minimum => 3
end
