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
    message = {}
    @reason = Reason.new(reason)
    if @reason.save
      message[:notice] = "Reason was successfully created"
    else
      message[:error] = @reason.errors.first.join(', ')
    end
    redirect resource(:reasons), :message => message
  end

  def update(id, reason)
    message = {}
    @reason = Reason.get(id)
    if @reason.update(reason)
      message[:notice] = "Reason was successfully updated"
    else
      message[:error] = @reason.errors.first.join(', ')
    end
    redirect resource(@reason), :message => message
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
