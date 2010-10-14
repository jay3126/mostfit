class Villages < Application
  # provides :xml, :yaml, :js
  before :get_area

  def index
    @villages = Village.all
    display @villages
  end

  def show(id)
    @village = Village.get(id)
    raise NotFound unless @village
    display @village
  end

  def new
    only_provides :html
    @village = Village.new
    display @village
  end

  def edit(id)
    only_provides :html
    @village = Village.get(id)
    raise NotFound unless @village
    display @village
  end

  def create(village)
    @village = Village.new(village)
    if @village.save
      redirect resource(@village), :message => {:notice => "Village was successfully created"}
    else
      message[:error] = "Village failed to be created"
      render :new
    end
  end

  def update(id, village)
    @village = Village.get(id)
    raise NotFound unless @village
    if @village.update(village)
       redirect resource(@village)
    else
      display @village, :edit
    end
  end

  def destroy(id)
    @village = Village.get(id)
    raise NotFound unless @village
    if @village.destroy
      redirect resource(:villages)
    else
      raise InternalServerError
    end
  end

  private
  def get_area
    @area = params[:area_id] ? Area.get(params[:area_id]) : nil
  end

end # Villages
