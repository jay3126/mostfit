class Reasons < Application
  # provides :xml, :yaml, :js

  def index
    @reasons = Reason.all
    display @reasons
  end

  def show(id)
    @reason = Reason.get(id)
    raise NotFound unless @reason
    display @reason
  end

  def new
    only_provides :html
    @reason = reason.new
    display @reason
  end

  def edit(id)
    only_provides :html
    @reason = Reason.get(id)
    raise NotFound unless @reason
    display @reason
  end

  def create(reason)
    @reason = Reason.new(reason)
    if @reason.save
      redirect resource(@reason), :message => {:notice => "Reason was successfully created"}
    else
      message[:error] = "Reason failed to be created"
      render :new
    end
  end

  def update(id, reason)
    @reason = Reason.get(id)
    raise NotFound unless @reason
    if @reason.update(reason)
      redirect resource(@reason)
    else
      display @reason, :edit
    end
  end

  def destroy(id)
    @reason = reason.get(id)
    raise NotFound unless @reason
    if @reason.destroy
      redirect resource(:reasons)
    else
      raise InternalServerError
    end
  end

end
