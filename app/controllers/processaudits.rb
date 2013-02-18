class Processaudits < Application
  # provides :xml, :yaml, :js

  def index
    @processaudits = Processaudit.all
    display @processaudits
  end

  def show(id)
    @processaudit = Processaudit.get(id)
    raise NotFound unless @processaudit
    display @processaudit
  end

  def new
    only_provides :html
    @processaudit = Processaudit.new
    display @processaudit
  end

  def edit(id)
    only_provides :html
    @processaudit = Processaudit.get(id)
    raise NotFound unless @processaudit
    display @processaudit
  end
 
  def create(processaudit)
    
    @processaudit = Processaudit.new(processaudit)
    
    if @processaudit.save
      redirect resource(@processaudit), :message => {:notice => "Processaudit was successfully created"}
    else
      message[:error] = "Processaudit failed to be created"
      render :new
    end
  end

  def update(id, processaudit)
    @processaudit = Processaudit.get(id)
    raise NotFound unless @processaudit
    if @processaudit.update(processaudit)
       redirect resource(@processaudit)
    else
      display @processaudit, :edit
    end
  end

  def destroy(id)
    @processaudit = Processaudit.get(id)
    raise NotFound unless @processaudit
    if @processaudit.destroy
      redirect resource(:processaudits)
    else
      raise InternalServerError
    end
  end

end # Processaudits
