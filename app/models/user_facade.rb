class UserFacade
  include Singleton

  ###########
  # QUERIES # on user begin
  ###########

  def get_user(for_login)
    #TODO
  end

  def get_first_user
    #TODO
  end

  def get_operator
    #TODO
  end

  ###########
  # QUERIES # on user end
  ###########

  def get_designation(for_staff_id, on_date)
    StaffAssignment.get_designation(for_staff_id, on_date)
  end

  ###########
  # UPDATES #
  ###########

  def assign_designation(designation, to_staff, performed_by, performed_at, effective_on = Date.today)
    StaffAssignment.assign(designation, to_staff, performed_by, performed_at, effective_on)
  end

end
