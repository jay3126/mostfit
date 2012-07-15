module Constants
  module User

    PRESENT_ATTENDANCE_STATUS = :present_attendance_status; ABSENT_ATTENDANCE_STATUS = :absent_attendance_status
    ATTENDANCE_STATUS_NOT_KNOWN = :attendance_status_not_known
    DEFAULT_ATTENDANCE_STATUS = ATTENDANCE_STATUS_NOT_KNOWN
    ATTENDANCE_STATUSES = [ATTENDANCE_STATUS_NOT_KNOWN, PRESENT_ATTENDANCE_STATUS, ABSENT_ATTENDANCE_STATUS]

    # When the ACL_DEBUG_MODE is set to true, a link that should be unavailable to the user
    # will still display as text, and not vanish altogether
    ENABLE_ACL_DEBUG_MODE = true

    EXECUTIVE = :executive; SUPERVISOR = :supervisor; SUPPORT = :support;
    READ_ONLY = :read_only;
    ACCOUNTANT = :accountant
    AUDITOR    = :auditor
    TELECALLER = :telecaller
    ADMINISTRATOR = :administrator; OPERATOR = :operator; FINOPS = :finops;
    ROLE_CLASSES = [ ADMINISTRATOR, OPERATOR , EXECUTIVE, SUPERVISOR, SUPPORT, FINOPS, READ_ONLY, ACCOUNTANT, AUDITOR, TELECALLER]
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

    ROLES_THAT_CAN_VIEW_ALL_LOCATIONS = [OPERATOR]

    VIEW_ACTIONS = ["index", "show"]
    MODIFY_ACTIONS = ["create", "new", "edit", "update", "destroy"]

  end
end
