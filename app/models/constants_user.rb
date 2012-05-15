module Constants
  module User

    EXECUTIVE = :executive; SUPERVISOR = :supervisor; SUPPORT = :support;
    READ_ONLY = :read_only; READ_ALL = :read_all;
    ADMINISTRATOR = :administrator; OPERATOR = :operator
    ROLE_CLASSES = [ ADMINISTRATOR, OPERATOR , EXECUTIVE, SUPERVISOR, SUPPORT, READ_ONLY, READ_ALL ]

  end
end
