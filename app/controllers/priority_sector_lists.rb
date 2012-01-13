class PrioritySectorLists < Application
  # provides :xml, :yaml, :js

  def index
    @priority_sector_lists = PrioritySectorList.all
    display @priority_sector_lists
  end

  def show(id)
    @priority_sector_list = PrioritySectorList.get(id)
    raise NotFound unless @priority_sector_list
    display @priority_sector_list
  end

  def new
    only_provides :html
    @priority_sector_list = PrioritySectorList.new
    display @priority_sector_list
  end

  def edit(id)
    only_provides :html
    @priority_sector_list = PrioritySectorList.get(id)
    raise NotFound unless @priority_sector_list
    display @priority_sector_list
  end

  def create(priority_sector_list)
    @priority_sector_list = PrioritySectorList.new(priority_sector_list)
    if @priority_sector_list.save
      redirect resource(@priority_sector_list), :message => {:notice => "PrioritySectorList was successfully created"}
    else
      message[:error] = "PrioritySectorList failed to be created"
      render :new
    end
  end

  def update(id, priority_sector_list)
    @priority_sector_list = PrioritySectorList.get(id)
    raise NotFound unless @priority_sector_list
    if @priority_sector_list.update(priority_sector_list)
       redirect resource(@priority_sector_list)
    else
      display @priority_sector_list, :edit
    end
  end

  def destroy(id)
    @priority_sector_list = PrioritySectorList.get(id)
    raise NotFound unless @priority_sector_list
    if @priority_sector_list.destroy
      redirect resource(:priority_sector_lists)
    else
      raise InternalServerError
    end
  end

  def psl_sub_categories
    if params[:id]
      priority_sector_list = PrioritySectorList.get(params[:id])
      next unless priority_sector_list
      return("<option value=''>Select sub-category</option>"+priority_sector_list.psl_sub_categories(:order => [:name]).map{|dr| "<option value=#{dr.id}>#{dr.name}</option>"}.join)
    end
  end

end # PrioritySectorLists
