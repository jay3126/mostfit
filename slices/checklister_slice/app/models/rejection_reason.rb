class RejectionReason
  include DataMapper::Resource

  property :id, Serial
  property :name, Text
  property :created_at, DateTime
  property :deleted_at, DateTime


  def self.generate_seed_data
    RejectionReason.create!(:name => "Member/Guarantor age other than criteria")
    RejectionReason.create!(:name => "Member/Guarantor cust ID not available")
    RejectionReason.create!(:name => "residence stability less than five years")
    RejectionReason.create!(:name => "Pair of relatives more than one")
    RejectionReason.create!(:name => "Family member already taken loan from us OR given loan with same RC")
    RejectionReason.create!(:name => "Distance from center more than 300 mtrs")
    RejectionReason.create!(:name => " Current address proof not available")
    RejectionReason.create!(:name => "JLG issue")
    RejectionReason.create!(:name => "Member not interested")
    RejectionReason.create!(:name => " Member/Guarantor name not in RC")
    RejectionReason.create!(:name => "Member has shown wrong house OR has given wrong information")
    RejectionReason.create!(:name => "Hold not clear")
    RejectionReason.create!(:name => "Member not eligible as per MFIN norms")
    RejectionReason.create!(:name => "End use of loan other than business")
    RejectionReason.create!(:name => " Don't have original documents")
    RejectionReason.create!(:name => "Other")
    RejectionReason.create!(:name => "Not rejected")
  end


end
