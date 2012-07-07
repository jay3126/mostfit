class ChecklisterSlice::FreeTexts < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    @free_texts = FreeText.all
    display @free_texts
  end

  def show(id)
    @free_text = FreeText.get(id)
    raise NotFound unless @free_text
    display @free_text
  end

  def new
    only_provides :html
    @free_text = FreeText.new
    display @free_text
  end

  def edit(id)
    only_provides :html
    @free_text = FreeText.get(id)
    raise NotFound unless @free_text
    display @free_text
  end

  def create(free_text)
    @free_text = FreeText.new(free_text)
    if @free_text.save
      redirect resource(@free_text), :message => {:notice => "FreeText was successfully created"}
    else
      message[:error] = "FreeText failed to be created"
      render :new
    end
  end

  def update(id, free_text)
    @free_text = FreeText.get(id)
    raise NotFound unless @free_text
    if @free_text.update(free_text)
       redirect resource(@free_text)
    else
      display @free_text, :edit
    end
  end

  def destroy(id)
    @free_text = FreeText.get(id)
    raise NotFound unless @free_text
    if @free_text.destroy
      redirect resource(:free_texts)
    else
      raise InternalServerError
    end
  end

end # FreeTexts
