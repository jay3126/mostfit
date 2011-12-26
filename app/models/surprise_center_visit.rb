class SurpriseCenterVisit
  # a center can have many surprise center visits.
  # they are carried out by a staff member and are as of a particular date

  include DataMapper::Resource
  
  property :id,      Serial
  property :done_on, Date

  belongs_to :center
  belongs_to :conducted_by, :model => StaffMember

  property :question_1, Boolean, :default => false
  property :question_2, Boolean, :default => false
  property :question_3, Boolean, :default => false
  property :question_4, Boolean, :default => false
  property :question_5, Boolean, :default => false
  property :question_6, Boolean, :default => false
  property :question_7, Boolean, :default => false
  property :question_8, Boolean, :default => false
  property :question_9, Boolean, :default => false
  property :question_10, Boolean, :default => false

  validates_with_method :done_on_is_earlier_than_center_creation_date

  def done_on_is_earlier_than_center_creation_date
    return true if self.done_on > ( self.center ? self.center.creation_date : Date.today )
    [false, "Surprise Center meeting cannot be done before the center has been created"]
  end
  
end
