class Guarantors < Application
  # provides :xml, :yaml, :js

  def index
    @guarantors = Guarantor.all
    display @guarantors
  end

  def show(id)
    @guarantor = Guarantor.get(id)
    raise NotFound unless @guarantor
    display @guarantor
  end

  def new
    only_provides :html
    @guarantor = Guarantor.new
    display @guarantor
  end

  def edit(id)
    only_provides :html
    @guarantor = Guarantor.get(id)
    raise NotFound unless @guarantor
    display @guarantor
  end

  def create(guarantor)
    @guarantor = Guarantor.new(guarantor)
   
    if @guarantor.save
      redirect resource(:guarantors), :message => {:notice => "Guarantor was successfully created"}
    else
      message[:error] = "Guarantor failed to be created"
      render :new
    end
  end


  def update(id, guarantor)
    @guarantor = Guarantor.get(id)
    raise NotFound unless @guarantor
    if @guarantor.update(guarantor)
       redirect resource(@guarantor)
    else
      display @guarantor, :edit
    end
  end

  def destroy(id)
    @guarantor = Guarantor.get(id)
    raise NotFound unless @guarantor
    if @guarantor.destroy
      redirect resource(:guarantors)
    else
      raise InternalServerError
    end
  end

end # Guarantors
