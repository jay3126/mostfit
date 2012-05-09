class CostCenters < Application
  # provides :xml, :yaml, :js

  def index
    @cost_centers = CostCenter.all
    display @cost_centers, :layout => layout?
  end

  def show(id)
    @cost_center = CostCenter.get(id)
    raise NotFound unless @cost_center
    display @cost_center
  end

  def new
    only_provides :html
    @cost_center = CostCenter.new
    display @cost_center
  end

  def edit(id)
    only_provides :html
    @cost_center = CostCenter.get(id)
    raise NotFound unless @cost_center
    display @cost_center
  end

  def create(cost_center)
    @cost_center = CostCenter.new(cost_center)
    if @cost_center.save
      redirect resource(@cost_center), :message => {:notice => "CostCenter was successfully created"}
    else
      message[:error] = "CostCenter failed to be created"
      render :new
    end
  end

  def update(id, cost_center)
    @cost_center = CostCenter.get(id)
    raise NotFound unless @cost_center
    if @cost_center.update(cost_center)
       redirect resource(@cost_center)
    else
      display @cost_center, :edit
    end
  end

  def destroy(id)
    @cost_center = CostCenter.get(id)
    raise NotFound unless @cost_center
    if @cost_center.destroy
      redirect resource(:cost_centers)
    else
      raise InternalServerError
    end
  end

end # CostCenters
