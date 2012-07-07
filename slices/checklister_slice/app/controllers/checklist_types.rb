class ChecklisterSlice::ChecklistTypes < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    @checklist_types =   ChecklistType.all
    display @checklist_types
  end

  def show(id)
    @checklist_type = ChecklistType.get(id)
    raise NotFound unless @checklist_type
    display @checklist_type
  end

  def new
    only_provides :html
    @checklist_type = ChecklistType.new
    display @checklist_type
  end

  def edit(id)
    only_provides :html
    @checklist_type = ChecklistType.get(id)
    raise NotFound unless @checklist_type
    display @checklist_type
  end

  def create(checklist_type)
    @checklist_type = ChecklistType.new(checklist_type)
    if @checklist_type.save
      redirect resource(@checklist_type), :message => {:notice => "ChecklistType was successfully created"}
    else
      message[:error] = "ChecklistType failed to be created"
      render :new
    end
  end

  def update(id, checklist_type)
    @checklist_type = ChecklistType.get(id)
    raise NotFound unless @checklist_type
    if @checklist_type.update(checklist_type)
       redirect resource(@checklist_type)
    else
      display @checklist_type, :edit
    end
  end

  def destroy(id)
    @checklist_type = ChecklistType.get(id)
    raise NotFound unless @checklist_type
    if @checklist_type.destroy
      redirect resource(:checklist_types)
    else
      raise InternalServerError
    end
  end

end # ChecklistTypes
