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

  def self.get_result_status(target_entity_type,target_entity_id)
    @target_entity=TargetEntity.all(:type=>target_entity_type.to_s,:name=>target_entity_id).first
    @healthcheck_checklist=ChecklistType.all(:name => "HealthCheck on Loan Files").first
    return false if @target_entity.nil? or @healthcheck_checklist.nil?

    @responses=@healthcheck_checklist.checklists.first.responses.all(:target_entity_id=>@target_entity.id)
    
    return true if @responses.all(:result_status => "cleared").count>0

    return false
  end

end
