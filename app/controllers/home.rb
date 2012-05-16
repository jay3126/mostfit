class Home < Application

  def index
    @user = session.user
    @staff = @user.staff_member.blank? ? @user  : @user.staff_member
    @effective_date = get_session_effective_date || Date.today
    display @user
  end
end