class ChecklisterSlice::FreeTextFillings < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    @free_text_fillings = FreeTextFilling.all
    display @free_text_fillings
  end

  def show(id)
    @free_text_filling = FreeTextFilling.get(id)
    raise NotFound unless @free_text_filling
    display @free_text_filling
  end

  def new
    only_provides :html
    @free_text_filling = FreeTextFilling.new
    display @free_text_filling
  end

  def edit(id)
    only_provides :html
    @free_text_filling = FreeTextFilling.get(id)
    raise NotFound unless @free_text_filling
    display @free_text_filling
  end

  def create(free_text_filling)
    @free_text_filling = FreeTextFilling.new(free_text_filling)
    if @free_text_filling.save
      redirect resource(@free_text_filling), :message => {:notice => "FreeTextFilling was successfully created"}
    else
      message[:error] = "FreeTextFilling failed to be created"
      render :new
    end
  end

  def update(id, free_text_filling)
    @free_text_filling = FreeTextFilling.get(id)
    raise NotFound unless @free_text_filling
    if @free_text_filling.update(free_text_filling)
       redirect resource(@free_text_filling)
    else
      display @free_text_filling, :edit
    end
  end

  def destroy(id)
    @free_text_filling = FreeTextFilling.get(id)
    raise NotFound unless @free_text_filling
    if @free_text_filling.destroy
      redirect resource(:free_text_fillings)
    else
      raise InternalServerError
    end
  end

end # FreeTextFillings
