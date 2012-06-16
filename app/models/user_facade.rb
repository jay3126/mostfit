class UserFacade
  include Singleton

  ###########
  # QUERIES # on user begin
  ###########

  def get_user(for_user_id)
    user_manager.get_user(for_user_id)
  end

  def get_user_for_login(login)
    user_manager.get_user_for_login(login)
  end

  def get_first_user
    user_manager.get_first_user
  end

  def get_operator
    user_manager.get_operator
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

  def user_manager
    @user_manager ||= UserManager.new
  end

end