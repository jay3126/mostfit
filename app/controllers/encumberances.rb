class Encumberances < Application
  # provides :xml, :yaml, :js

  def index
    @encumberances = Encumberance.all
    display @encumberances
  end

  def show(id)
    @encumberance = Encumberance.get(id)
    raise NotFound unless @encumberance
    display @encumberance
  end

  def new
    only_provides :html
    @encumberance = Encumberance.new
    display @encumberance
  end

  def edit(id)
    only_provides :html
    @encumberance = Encumberance.get(id)
    raise NotFound unless @encumberance
    display @encumberance
  end

  def create(encumberance)
    @encumberance = Encumberance.new(encumberance)
    @money=MoneyManager.get_money_instance(:assigned_value)
    @encumberance.currency=@money.currency
    #@encumberance.assigned_value=@money.amount

    if @encumberance.save
      #redirect resource(@encumberance), :message => {:notice => "Encumberance was successfully created"}
      redirect resource(:encumberances), :message => {:notice => "Encumberance was successfully created"}
    else
      message[:error] = "Encumberance failed to be created"
      render :new
    end
  end

  def update(id, encumberance)
    @encumberance = Encumberance.get(id)
    raise NotFound unless @encumberance
    if @encumberance.update(encumberance)
       redirect resource(@encumberance)
    else
      display @encumberance, :edit
    end
  end

  def destroy(id)
    @encumberance = Encumberance.get(id)
    raise NotFound unless @encumberance
    if @encumberance.destroy
      redirect resource(:encumberances)
    else
      raise InternalServerError
    end
  end

  def upload_data(id)
    @id=id
    @encumberance=Encumberance.get(id)
    @upload = Upload.new
    display @upload
  end

end # Encumberances
