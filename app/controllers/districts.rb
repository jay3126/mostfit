class Districts < Application
  provides :xml, :yaml, :js
  include DateParser
  before :get_area

  def index
    @districts = @area ? @area.districts : District.all
    display @districts
  end

  def show(id)
    @district = District.get(id)
    raise NotFound unless @district
    display @district
  end

  def new
    only_provides :html
    @district = District.new
    display @district
  end

  def edit(id)
    only_provides :html
    @district = District.get(id)
    raise NotFound unless @district
    display @district
  end

  def create(district)
    @district = District.new(district)
    if @district.save
      redirect resource(@district), :message => {:notice => "District was successfully created"}
    else
      message[:error] = "District failed to be created"
      render :new
    end
  end

  def update(id, district)
    @district = District.get(id)
    raise NotFound unless @district
    if @district.update(district)
       redirect resource(@district)
    else
      display @district, :edit
    end
  end

  def destroy(id)
    @district = District.get(id)
    raise NotFound unless @district
    if @district.destroy
      redirect resource(:districts)
    else
      raise InternalServerError
    end
  end

  def branches
    if params[:id]
      district = District.get(params[:id])
      next unless district
      return("<option value=''>Select branch</option>"+district.branches(:order => [:name]).map{|br| "<option value=#{br.id}>#{br.name}</option>"}.join)
    end
  end

  private 
  def get_area
    @area = params[:area_id] ? Area.get(params[:area_id].to_i) : nil
  end

end # Districts
