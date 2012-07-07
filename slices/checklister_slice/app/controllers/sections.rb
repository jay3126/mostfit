class ChecklisterSlice::Sections < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    @sections = Section.all
    display @sections
  end

  def show(id)
    @section = Section.get(id)
    raise NotFound unless @section
    display @section
  end

  def new
    only_provides :html
    @section = Section.new
    display @section
  end

  def edit(id)
    only_provides :html
    @section = Section.get(id)
    raise NotFound unless @section
    display @section
  end

  def create(section)
    @section = Section.new(section)
    if @section.save
      redirect resource(@section), :message => {:notice => "Section was successfully created"}
    else
      message[:error] = "Section failed to be created"
      render :new
    end
  end

  def update(id, section)
    @section = Section.get(id)
    raise NotFound unless @section
    if @section.update(section)
       redirect resource(@section)
    else
      display @section, :edit
    end
  end

  def destroy(id)
    @section = Section.get(id)
    raise NotFound unless @section
    if @section.destroy
      redirect resource(:sections)
    else
      raise InternalServerError
    end
  end

end # Sections
