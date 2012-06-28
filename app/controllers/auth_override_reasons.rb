class AuthOverrideReasons < Application

  def index
    if session.user.role == :admin
      @auth_override_reasons = @auth_override_reasons || AuthOverrideReason.all(:deleted=>false)
      display @auth_override_reasons
    else
      redirect(params[:return], :message => {:notice => "You dont have sufficient privilleges"})
    end
  end

  def show(id)
    @auth_override_reason = AuthOverrideReason.get(id)
    raise NotFound unless @auth_override_reason
    display @auth_override_reason
  end

  def new
    if session.user.role == :admin
      @auth_override_reason=AuthOverrideReason.new
      display @auth_override_reason
    else
      redirect(params[:return], :message => {:notice => "You dont have sufficient privilleges"})
    end
  end

	def change_state(id)
		@auth_override_reason = AuthOverrideReason.get(id)
		@auth_override_reason.active=!@auth_override_reason.active
		if @auth_override_reason.save!
			redirect("/auth_override_reasons", :message => {:notice => "Loan authorized override reason'#{@auth_override_reason.reason}' (Id:#{@auth_override_reason.id}) state changed"})
    else
			redirect("/auth_override_reasons", :message => {:notice => "Loan authorized override reason'#{@auth_override_reason.reason}' (Id:#{@auth_override_reason.id}) failed to be updated"})			
    end
	end

  def edit(id)
    only_provides :html
    @auth_override_reason = AuthOverrideReason.get(id)
    @auth_override_reasons = @auth_override_reasons || AuthOverrideReason.all
    raise NotFound unless @auth_override_reason
    display @auth_override_reason
  end

  def create(auth_override_reason)
    if session.user.role == :admin
      @auth_override_reason = AuthOverrideReason.new(auth_override_reason)
      @auth_override_reason.created_by_id = session.user.id
      if(AuthOverrideReason.all(:reason => @auth_override_reason.reason).count==0)
        if @auth_override_reason.save!
          redirect("/auth_override_reasons", :message => {:notice => "Loan authorized override reasons'#{@auth_override_reason.reason}' (Id:#{@auth_override_reason.id}) successfully created"})
        else
          message[:error] = "Loan authorized override reasons failed to be created"
          render :new  # error messages will show
        end
      else
        message[:error] = "Loan authorized override reasons with same name already exists !"
        render :new  # error messages will show
      end
    else
      redirect("/auth_override_reasons", :message => {:notice => "You dont have sufficient privilleges"})
    end
  end  

  def update(id, auth_override_reason)
    @auth_override_reason = AuthOverrideReason.get(id)
    raise NotFound unless @auth_override_reason
    if @auth_override_reason.update(auth_override_reason)
      redirect resource(@auth_override_reason)
    else
      display @auth_override_reason,:edit
    end
  end

  def destroy(id)
    @auth_override_reason = AuthOverrideReason.get(id)
    raise NotFound unless @auth_override_reason
    @temp=@auth_override_reason
    @auth_override_reason.deleted_by_id=session.user.id
    if @auth_override_reason.destroy
      redirect("/auth_override_reasons", :message => {:notice => "Loan authorized override reasons'#{@temp.reason}' (Id:#{@temp.id}) successfully deleted"})
    else
      redirect("/auth_override_reasons", :message => {:notice => "Loan authorized override reasons'#{@temp.reason}' (Id:#{@temp.id}) not successfully deleted"})
    end
  end
  
end  # AuthOverrideReasons