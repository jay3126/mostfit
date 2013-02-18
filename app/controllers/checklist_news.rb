class ChecklistNews < Application
  # provides :xml, :yaml, :js

  def index
    @checklist_news = Checklist.all
    display @checklist_news
  end

  def show(id)
    @checklist_news = Checklist.get(id)
    raise NotFound unless @checklist_news
    display @checklist_news
  end

  def new
    only_provides :html
    @checklist_news = Checklist.new
    display @checklist_news
  end

  def edit(id)
    only_provides :html
    @checklist_news = Checklist.get(id)
    raise NotFound unless @checklist_news
    display @checklist_news
  end

  def create(checklist_news)
    @checklist_news = Checklist.new(checklist_news)
    if @checklist_news.save
      redirect resource(@checklist_news), :message => {:notice => "Checklist was successfully created"}
    else
      message[:error] = "Checklist failed to be created"
      render :new
    end
  end

  def update(id, checklist_news)
    @checklist_news = Checklist.get(id)
    raise NotFound unless @checklist_news
    if @checklist_news.update(checklist_news)
       redirect resource(@checklist_news)
    else
      display @checklist_news, :edit
    end
  end

  def destroy(id)
    @checklist_news = Checklist.get(id)
    raise NotFound unless @checklist_news
    if @checklist_news.destroy
      redirect resource(:checklist_news)
    else
      raise InternalServerError
    end
  end

end # ChecklistNews
