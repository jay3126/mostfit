class ChecklisterSlice::Fillers < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    @fillers = Filler.all
    display @fillers
  end

  def show(id)
    @filler = Filler.get(id)
    raise NotFound unless @filler
    display @filler
  end

  def new
    only_provides :html
    @filler = Filler.new
    display @filler
  end

  def edit(id)
    only_provides :html
    @filler = Filler.get(id)
    raise NotFound unless @filler
    display @filler
  end

  def create(filler)
    @filler = Filler.new(filler)
    if @filler.save
      redirect resource(@filler), :message => {:notice => "Filler was successfully created"}
    else
      message[:error] = "Filler failed to be created"
      render :new
    end
  end

  def update(id, filler)
    @filler = Filler.get(id)
    raise NotFound unless @filler
    if @filler.update(filler)
       redirect resource(@filler)
    else
      display @filler, :edit
    end
  end

  def destroy(id)
    @filler = Filler.get(id)
    raise NotFound unless @filler
    if @filler.destroy
      redirect resource(:fillers)
    else
      raise InternalServerError
    end
  end

end # Fillers
