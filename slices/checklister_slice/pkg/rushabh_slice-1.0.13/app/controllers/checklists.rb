class ChecklisterSlice::Checklists < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    @checklists = Checklist.all
    display @checklists
  end

  def show(id)
    @checklist = Checklist.get(id)
    raise NotFound unless @checklist
    display @checklist
  end

  def new
    only_provides :html
    @checklist = Checklist.new
    display @checklist
  end

  def edit(id)
    only_provides :html
    @checklist = Checklist.get(id)
    raise NotFound unless @checklist
    display @checklist
  end

  def create(checklist)
    @checklist = Checklist.new(checklist)
    if @checklist.save
      redirect resource(@checklist), :message => {:notice => "Checklist was successfully created"}
    else
      message[:error] = "Checklist failed to be created"
      render :new
    end
  end

  def update(id, checklist)
    @checklist = Checklist.get(id)
    raise NotFound unless @checklist
    if @checklist.update(checklist)
       redirect resource(@checklist)
    else
      display @checklist, :edit
    end
  end

  def destroy(id)
    @checklist = Checklist.get(id)
    raise NotFound unless @checklist
    if @checklist.destroy
      redirect resource(:checklists)
    else
      raise InternalServerError
    end
  end

end # Checklists
