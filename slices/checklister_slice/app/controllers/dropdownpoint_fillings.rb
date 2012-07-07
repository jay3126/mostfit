class ChecklisterSlice::DropdownpointFillings < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    @dropdownpoint_fillings = DropdownpointFilling.all
    display @dropdownpoint_fillings
  end

  def show(id)
    @dropdownpoint_filling = DropdownpointFilling.get(id)
    raise NotFound unless @dropdownpoint_filling
    display @dropdownpoint_filling
  end

  def new
    only_provides :html
    @dropdownpoint_filling = DropdownpointFilling.new
    display @dropdownpoint_filling
  end

  def edit(id)
    only_provides :html
    @dropdownpoint_filling = DropdownpointFilling.get(id)
    raise NotFound unless @dropdownpoint_filling
    display @dropdownpoint_filling
  end

  def create(dropdownpoint_filling)
    @dropdownpoint_filling = DropdownpointFilling.new(dropdownpoint_filling)
    if @dropdownpoint_filling.save
      redirect resource(@dropdownpoint_filling), :message => {:notice => "DropdownpointFilling was successfully created"}
    else
      message[:error] = "DropdownpointFilling failed to be created"
      render :new
    end
  end

  def update(id, dropdownpoint_filling)
    @dropdownpoint_filling = DropdownpointFilling.get(id)
    raise NotFound unless @dropdownpoint_filling
    if @dropdownpoint_filling.update(dropdownpoint_filling)
       redirect resource(@dropdownpoint_filling)
    else
      display @dropdownpoint_filling, :edit
    end
  end

  def destroy(id)
    @dropdownpoint_filling = DropdownpointFilling.get(id)
    raise NotFound unless @dropdownpoint_filling
    if @dropdownpoint_filling.destroy
      redirect resource(:dropdownpoint_fillings)
    else
      raise InternalServerError
    end
  end

end # DropdownpointFillings
