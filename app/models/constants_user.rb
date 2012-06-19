module Constants
  module User

    EXECUTIVE = :executive; SUPERVISOR = :supervisor; SUPPORT = :support;
    READ_ONLY = :read_only; READ_ALL = :read_all;
    ADMINISTRATOR = :administrator; OPERATOR = :operator
    ROLE_CLASSES = [ ADMINISTRATOR, OPERATOR , EXECUTIVE, SUPERVISOR, SUPPORT, READ_ONLY, READ_ALL ]
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
