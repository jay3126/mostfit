class ChecklisterSlice::Checkpoints < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    @checkpoints = Checkpoint.all
    display @checkpoints
  end

  def show(id)
    @checkpoint = Checkpoint.get(id)
    raise NotFound unless @checkpoint
    display @checkpoint
  end

  def new
    only_provides :html
    @checkpoint = Checkpoint.new
    display @checkpoint
  end

  def edit(id)
    only_provides :html
    @checkpoint = Checkpoint.get(id)
    raise NotFound unless @checkpoint
    display @checkpoint
  end

  def create(checkpoint)
    @checkpoint = Checkpoint.new(checkpoint)
    if @checkpoint.save
      redirect resource(@checkpoint), :message => {:notice => "Checkpoint was successfully created"}
    else
      message[:error] = "Checkpoint failed to be created"
      render :new
    end
  end

  def update(id, checkpoint)
    @checkpoint = Checkpoint.get(id)
    raise NotFound unless @checkpoint
    if @checkpoint.update(checkpoint)
       redirect resource(@checkpoint)
    else
      display @checkpoint, :edit
    end
  end

  def destroy(id)
    @checkpoint = Checkpoint.get(id)
    raise NotFound unless @checkpoint
    if @checkpoint.destroy
      redirect resource(:checkpoints)
    else
      raise InternalServerError
    end
  end

end # Checkpoints
