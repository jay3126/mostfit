class DeviationType
  include DataMapper::Resource

  property :id, Serial
  property :name, String ,:nullable=>false

  validates_is_unique :name


  def self.generate_seed_data
    DeviationType.create!(:name => "Center Leader as Guarantor")
    DeviationType.create!(:name => "Distance from center place more than criteria")
    DeviationType.create!(:name => "Relatives more than criteria")
    DeviationType.create!(:name => "KYC related")
    DeviationType.create!(:name => "Guarantor age other than criteria")
    DeviationType.create!(:name => "Member age other than criteria")
    DeviationType.create!(:name => "Guarantor other than blood relative")
    DeviationType.create!(:name => "Name mismatch")
    DeviationType.create!(:name => "Other")


  end


end
