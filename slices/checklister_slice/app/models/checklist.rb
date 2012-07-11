class Checklist
  include DataMapper::Resource

  property :id, Serial
  property :name, Text, :nullable => false

  property :created_at, DateTime, :nullable => false, :default => Date.today
  property :deleted_at, DateTime


  has n, :sections
  has n, :responses

  belongs_to :checklist_type


  def self.get_result_status(target_entity_type,target_entity_id)
    @target_enity=TargetEntity.all(:type=>target_entity_type.to_s,:model_record_id=>target_entity_id).first
    @healthcheck_checklist=ChecklistType.all(:name => "HealthCheck on Loan Files").first
    @responses=@healthcheck_checklist.checklists.first.responses.all(:target_entity_id=>@target_enity.id)
    if @responses.all(:result_status => "cleared").count>0
      return true

    else
      return false
    end


  end


end
