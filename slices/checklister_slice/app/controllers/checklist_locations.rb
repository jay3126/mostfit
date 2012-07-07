class ChecklisterSlice::ChecklistLocations < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    @checklist_locations = ChecklistLocation.all
    display @checklist_locations
  end

  def show(id)
    @checklist_location = ChecklistLocation.get(id)
    raise NotFound unless @checklist_location
    display @checklist_location
  end

  def new
    only_provides :html
    @checklist_location = ChecklistLocation.new
    display @checklist_location
  end

  def edit(id)
    only_provides :html
    @checklist_location = ChecklistLocation.get(id)
    raise NotFound unless @checklist_location
    display @checklist_location
  end

  def create(checklist_location)
    @checklist_location = ChecklistLocation.new(checklist_location)
    if @checklist_location.save
      redirect resource(@checklist_location), :message => {:notice => "ChecklistLocation was successfully created"}
    else
      message[:error] = "ChecklistLocation failed to be created"
      render :new
    end
  end

  def update(id, checklist_location)
    @checklist_location = ChecklistLocation.get(id)
    raise NotFound unless @checklist_location
    if @checklist_location.update(checklist_location)
       redirect resource(@checklist_location)
    else
      display @checklist_location, :edit
    end
  end

  def destroy(id)
    @checklist_location = ChecklistLocation.get(id)
    raise NotFound unless @checklist_location
    if @checklist_location.destroy
      redirect resource(:checklist_locations)
    else
      raise InternalServerError
    end
  end

end # ChecklistLocations
