class ChecklisterSlice::Dropdownpoints < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    @dropdownpoints = Dropdownpoint.all
    display @dropdownpoints
  end

  def show(id)
    @dropdownpoint = Dropdownpoint.get(id)
    raise NotFound unless @dropdownpoint
    display @dropdownpoint
  end

  def new
    only_provides :html
    @dropdownpoint = Dropdownpoint.new
    display @dropdownpoint
  end

  def edit(id)
    only_provides :html
    @dropdownpoint = Dropdownpoint.get(id)
    raise NotFound unless @dropdownpoint
    display @dropdownpoint
  end

  def create(dropdownpoint)
    @dropdownpoint = Dropdownpoint.new(dropdownpoint)
    if @dropdownpoint.save
      redirect resource(@dropdownpoint), :message => {:notice => "Dropdownpoint was successfully created"}
    else
      message[:error] = "Dropdownpoint failed to be created"
      render :new
    end
  end

  def update(id, dropdownpoint)
    @dropdownpoint = Dropdownpoint.get(id)
    raise NotFound unless @dropdownpoint
    if @dropdownpoint.update(dropdownpoint)
       redirect resource(@dropdownpoint)
    else
      display @dropdownpoint, :edit
    end
  end

  def destroy(id)
    @dropdownpoint = Dropdownpoint.get(id)
    raise NotFound unless @dropdownpoint
    if @dropdownpoint.destroy
      redirect resource(:dropdownpoints)
    else
      raise InternalServerError
    end
  end

end # Dropdownpoints
