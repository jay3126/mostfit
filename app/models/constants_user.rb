module Constants
  module User

    # When the ACL_DEBUG_MODE is set to true, a link that should be unavailable to the user
    # will still display as text, and not vanish altogether
    ENABLE_ACL_DEBUG_MODE = true

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

    ROLES_THAT_CAN_VIEW_ALL_LOCATIONS = [FINOPS, READ_ONLY]

    VIEW_ACTIONS = ["index", "show"]
    MODIFY_ACTIONS = ["create", "new", "edit", "update", "destroy"]

  end
end
