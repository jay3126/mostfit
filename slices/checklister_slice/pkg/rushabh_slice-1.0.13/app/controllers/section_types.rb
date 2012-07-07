class ChecklisterSlice::SectionTypes < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    @section_types = SectionType.all
    display @section_types
  end

  def show(id)
    @section_type = SectionType.get(id)
    raise NotFound unless @section_type
    display @section_type
  end

  def new
    only_provides :html
    @section_type = SectionType.new
    display @section_type
  end

  def edit(id)
    only_provides :html
    @section_type = SectionType.get(id)
    raise NotFound unless @section_type
    display @section_type
  end

  def create(section_type)
    @section_type = SectionType.new(section_type)
    if @section_type.save
      redirect resource(@section_type), :message => {:notice => "SectionType was successfully created"}
    else
      message[:error] = "SectionType failed to be created"
      render :new
    end
  end

  def update(id, section_type)
    @section_type = SectionType.get(id)
    raise NotFound unless @section_type
    if @section_type.update(section_type)
       redirect resource(@section_type)
    else
      display @section_type, :edit
    end
  end

  def destroy(id)
    @section_type = SectionType.get(id)
    raise NotFound unless @section_type
    if @section_type.destroy
      redirect resource(:section_types)
    else
      raise InternalServerError
    end
  end

end # SectionTypes
