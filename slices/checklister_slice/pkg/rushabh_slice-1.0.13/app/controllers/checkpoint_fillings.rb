class ChecklisterSlice::CheckpointFillings < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    @checkpoint_fillings = CheckpointFilling.all
    display @checkpoint_fillings
  end

  def show(id)
    @checkpoint_filling = CheckpointFilling.get(id)
    raise NotFound unless @checkpoint_filling
    display @checkpoint_filling
  end

  def new
    only_provides :html
    @checkpoint_filling = CheckpointFilling.new
    display @checkpoint_filling
  end

  def edit(id)
    only_provides :html
    @checkpoint_filling = CheckpointFilling.get(id)
    raise NotFound unless @checkpoint_filling
    display @checkpoint_filling
  end

  def create(checkpoint_filling)
    @checkpoint_filling = CheckpointFilling.new(checkpoint_filling)
    if @checkpoint_filling.save
      redirect resource(@checkpoint_filling), :message => {:notice => "CheckpointFilling was successfully created"}
    else
      message[:error] = "CheckpointFilling failed to be created"
      render :new
    end
  end

  def update(id, checkpoint_filling)
    @checkpoint_filling = CheckpointFilling.get(id)
    raise NotFound unless @checkpoint_filling
    if @checkpoint_filling.update(checkpoint_filling)
       redirect resource(@checkpoint_filling)
    else
      display @checkpoint_filling, :edit
    end
  end

  def destroy(id)
    @checkpoint_filling = CheckpointFilling.get(id)
    raise NotFound unless @checkpoint_filling
    if @checkpoint_filling.destroy
      redirect resource(:checkpoint_fillings)
    else
      raise InternalServerError
    end
  end

end # CheckpointFillings
