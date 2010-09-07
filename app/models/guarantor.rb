class Guarantor
  include DataMapper::Resource

  property :id,   Serial
  property :legacy_id, String 
  property :name, String, :index => true
  property :father_name, String, :index => true
  property :date_of_birth, Date
  property :address, String 
  property :relationship_to_client, Enum.send('[]', *['', 'spouse', 'brother', 'brother_in_law', 'father', 'father_in_law', 'adult_son', 'other']), :default => '', :nullable => true, :lazy => true
 
  belongs_to :client
  belongs_to :guarantor_occupation, :nullable => true, :child_key => [:guarantor_occupation_id], :model => 'Occupation'  
  validates_present :name
  validates_present :father_name
  validates_length :name,   :minimum => 3
  validates_length :father_name,   :minimum => 3
end
