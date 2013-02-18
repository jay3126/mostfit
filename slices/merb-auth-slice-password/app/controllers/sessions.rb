class MerbAuthSlicePassword::Sessions < MerbAuthSlicePassword::Application
  
  before :_maintain_auth_session_before, :exclude => [:destroy]  # Need to hang onto the redirection during the session.abandon!
  before :_abandon_session,     :only => [:update, :destroy]
  before  :_maintain_auth_session_after,  :exclude => [:destroy]  # Need to hang onto the redirection during the session.abandon!
  before :ensure_authenticated, :only => [:update]
  before :check_multiple_login, :only => [:update]


  # redirect from an after filter for max flexibility
  # We can then put it into a slice and ppl can easily 
  # customize the action
  after :redirect_after_login,  :only => :update, :if => lambda{ !(300..399).include?(status) }
  after :redirect_after_logout, :only => :destroy
  
  def update
    "Add an after filter to do stuff after login"
    # this is where the default scope hooks go
  end

  def session_off
   
  end

  def destroy
    "Add an after filter to do stuff after logout"
  end
  
  
  private
  def check_multiple_login
    last_login = session.user.login_instances.last
    if params[:session_destory] == "true"
      last_login.update(:logout_time => Time.now, :logout_date => Time.now.strftime("%d-%m-%Y")) unless last_login.blank?
      session.abandon!
      message[:notice] = "The User's Session Terminated Successfully"
      redirect "/login", :message => message
    else
      if last_login.blank? || !last_login.logout_time.blank?
        login_instance = session.user.login_instances.new(:login_time => Time.now, :login_date => Time.now.strftime("%d-%m-%Y"))
        login_instance.save
        session.merge!(:login_id => login_instance.id)
      else
        if last_login.logout_time.blank?
          session.abandon!
          message[:error] = "This User already login to another system"
          redirect "/login", :message => message
        end
      end
    end
  end
  # @overwritable
  def redirect_after_login
    message[:notice] = "Authenticated Successfully"
    case session.user.role
    when :data_entry
      redirect url(:data_entry)
    when :staff_member
      redirect(url(:browse))
    when :maintainer
      redirect("/maintain#deployment")
    else
      redirect_back_or(url(:controller => :home, :action => 'index'), :message => message, :ignore => [slice_url(:login), slice_url(:logout)])
    end
  end

  # @overwritable
  def redirect_after_logout
    message[:notice] = "Logged Out"
    redirect "/login", :message => message
  end  

  # @private
  def _maintain_auth_session_before
    @_maintain_auth_session = {}
    Merb::Authentication.maintain_session_keys.each do |k|
      @_maintain_auth_session[k] = session[k]
    end
  end
  
  # @private
  def _maintain_auth_session_after
    @_maintain_auth_session.each do |k,v|
      session[k] = v
    end
  end
  
  # @private
  def _abandon_session
    user = session.user
    unless user.blank?
      last_login = user.login_instances.last
      last_login.update(:logout_time => Time.now, :logout_date => Time.now.strftime("%d-%m-%Y")) unless last_login.blank?
    end
    session.abandon!
  end
end
