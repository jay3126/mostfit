class Checklist
  include DataMapper::Resource

  property :id, Serial
  property :name, Text, :nullable => false

  property :created_at, DateTime, :nullable => false, :default => Date.today
  property :deleted_at, DateTime


  has n, :sections
  has n, :responses

  belongs_to :checklist_type


  def self.is_healthcheck_complete?(loan_file_identifier)
    get_result_status("LoanFile", loan_file_identifier)
  end

  def self.is_scv_complete?(center_identifier,on_date)
    get_completion_status("LocationLevel", center_identifier,on_date)
  end

  def self.get_result_status(target_entity_type, target_entity_id)
    @target_entity=TargetEntity.all(:type => target_entity_type.to_s, :name => target_entity_id).first
    @healthcheck_checklist=ChecklistType.all(:name => "HealthCheck on Loan Files").first
    return false if @target_entity.nil? or @healthcheck_checklist.nil?

    @responses=@healthcheck_checklist.checklists.first.responses.all(:target_entity_id => @target_entity.id)

    return true if @responses.all(:result_status.not => "pending").count>0

    return false
  end

  def self.get_hc_result_status(target_entity_type, target_entity_id)
    @target_entity=TargetEntity.all(:type => target_entity_type.to_s, :name => target_entity_id).first
    @healthcheck_checklist=ChecklistType.all(:name => "HealthCheck on Loan Files").first
    return 'Pending' if @target_entity.nil? or @healthcheck_checklist.nil?

    @response=@healthcheck_checklist.checklists.first.responses.first(:target_entity_id => @target_entity.id)

    @response.blank? ? 'Pending' : @response.result_status.humanize
  end


  def self.get_completion_status(target_entity_type, target_entity_id,on_date)
    @target_entity=TargetEntity.all(:type => target_entity_type.to_s, :name => target_entity_id).first
    @scv_checklist=ChecklistType.all(:name => "Surprise Center Visit").first
    return false if @target_entity.nil? or @scv_checklist.nil?

    @responses=@scv_checklist.checklists.first.responses.all(:target_entity_id => @target_entity.id,:value_date=>on_date)

    required_information_array=Array.new
    if @responses.all(:completed_status => "completed").count>0
      response=@responses.first
      filler=Filler.get(response.filler_id)
      required_information_array=[true,filler.model_record_id]
      return required_information_array

    end

    return false

  end

  def get_responses(target_entity_type, target_entity_id)
    self.responses.all('target_entity.type' => target_entity_type, 'target_entity.model_record_id' => target_entity_id)
  end

  def get_mandatory_fields
    case self.checklist_type.name
    when "Surprise Center Visit"
      fields = []
    when "Business Audit"
      fields = []
    when "Process Audit"
      fields = []
    when "HealthCheck on Loan Files"
      fields = []
    when "Customer Calling"
      fields = []
    else
      fields = []
    end
    fields
  end
end
