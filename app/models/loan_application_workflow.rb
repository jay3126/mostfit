module LoanApplicationWorkflow
  include Constants::Status

  # These are the stages in the life cycle of a loan application
  LIFE_CYCLE_STAGES = [:creation, :cpv, :dedupe, :overlap_report, :authorization, :loan_file_generation]

  # Each set of states maps to a stage in the life cycle of a loan application
  STAGES_AND_STATUSES = {
    CREATION_STATUSES => :creation,
    CPV_STATUSES => :cpv,
    DEDUPE_STATUSES => :dedupe,
    OVERLAP_REPORT_STATUSES => :overlap_report,
    AUTHORIZATION_STATUSES => :authorization,
    LOAN_FILE_GENERATION_STATUSES => :loan_file_generation
  }

  #Returns the life-cycle stage using the value of status
  def get_life_cycle_stage
    STAGES_AND_STATUSES[get_life_cycle_status]
  end

  # Returns the 'family' of status
  def get_life_cycle_status
    my_status = get_status
    STAGES_AND_STATUSES.keys.detect {|states| states.include?(my_status)}
  end

  # Whether the loan application is past a particular stage in the life cycle
  def past_life_cycle_stage?(stage)
    current_stage = get_life_cycle_stage
    LIFE_CYCLE_STAGES.index(current_stage) > LIFE_CYCLE_STAGES.index(stage)
  end
    
end