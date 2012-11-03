class Response
  include DataMapper::Resource
  COMPLETE_COMPLETION_STATUS = "complete"; INCOMPLETE_COMPLETION_STATUS = "incomplete"
  PENDING_RESULT_STATUS="pending"; CLEARED_RESULT_STATUS="cleared"; OVERRIDE = "override"

  COMPLETION_STATUSES=[COMPLETE_COMPLETION_STATUS, INCOMPLETE_COMPLETION_STATUS]

  RESULT_STATUSES=[PENDING_RESULT_STATUS, CLEARED_RESULT_STATUS, OVERRIDE]

  #TODO: the place should be an id corresponding to master in the database

  property :id, Serial
  property :created_at, DateTime, :nullable => false, :default => Date.today
  property :deleted_at, DateTime
  property :value_date, DateTime, :nullable => false, :default => Date.today
  #
  property :completion_status, Enum.send('[]', *COMPLETION_STATUSES), :nullable => false, :index => true
  property :result_status, Enum.send('[]', *RESULT_STATUSES), :nullable => false, :index => true

  belongs_to :target_entity
  belongs_to :filler
  belongs_to :checklist


  has n, :checkpoint_fillings
  has n, :free_text_fillings
  has n, :checklist_locations


  def get_deviation_type
    self.checklist.sections.first.dropdownpoints.first.dropdownpoint_fillings.all(:response_id => self.id).first.model_record_name
  end


end
