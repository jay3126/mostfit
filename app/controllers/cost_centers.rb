class CostCenters < Application
  # provides :xml, :yaml, :js

  def index
    @course_product = params[:course_product]
    @cost_center = params[:cost_center_id].blank? ? CostCenter.first(:name => 'Head Office') : CostCenter.get(params[:cost_center_id].to_i)
    display @cost_center
  end

  def show(id)
    @cost_center = CostCenter.get(id)
    raise NotFound unless @cost_center
    display @cost_center
  end

  def new
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
    @cost_center = CostCenter.new(:name => cost_center[:name], :biz_location_id => cost_center[:biz_location])
    if @cost_center.save
      redirect resource(:cost_centers), :message => {:notice => "CostCenter was successfully created"}
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
