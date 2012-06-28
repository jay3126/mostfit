module Constants
  module User

    EXECUTIVE = :executive; SUPERVISOR = :supervisor; SUPPORT = :support;
    READ_ONLY = :read_only; 
    ADMINISTRATOR = :administrator; OPERATOR = :operator; FINOPS = :finops;
    ROLE_CLASSES = [ ADMINISTRATOR, OPERATOR , EXECUTIVE, SUPERVISOR, SUPPORT, FINOPS, READ_ONLY]
    EXECUTIVE_CAN_MODIFY = [:occupations]
    EXECUTIVE_CAN_VIEW = [:loan_purposes, :branches]
    ACCESS = {
      :modify => {
        EXECUTIVE => EXECUTIVE_CAN_MODIFY
      },
      :view => {
        EXECUTIVE => EXECUTIVE_CAN_VIEW
      }
    }

    VIEW_ACTIONS = ["index", "show"]
    MODIFY_ACTIONS = ["create", "new", "edit", "update", "destroy"]

  end
end
