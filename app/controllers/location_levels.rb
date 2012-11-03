class LocationLevels < Application

  def index
    @location_levels = LocationLevel.all
    level            = LocationLevel.level_number_for_new
    @location_level  = LocationLevel.new(:level => level)
    display @location_levels
  end

  def edit
  end

  def create

    # INITIALIZING VARIABLES USED THROUGHTOUT

    message = {}

    # GATE-KEEPING

    l_level         = params[:location_level][:level].to_i
    l_name          = params[:location_level][:name]
    l_creation_date = params[:location_level][:creation_date]

    # VALIDATIONS

    message[:error] = "Location Level cannot be blank" if l_level.blank?
    message[:error] = "Location Level is not valid" unless l_level == LocationLevel.level_number_for_new
    message[:error] = "Location Name cannot be blank" if l_name.blank?
    message[:error] = "Creation Date cannot be blank" if l_creation_date.blank?

    # OPERATIONS PERFORMED
    if message[:error].blank?
      begin
        location_level = LocationLevel.create_next_level(l_name, l_creation_date)
        if location_level.new?
          message = {:error => location_level.errors.first.join(', ')}
        else
          message = {:notice => "Location Level successfully created"}
        end
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    redirect resource(:location_levels), :message => message
  
  end

  def show
    @location_level = LocationLevel.get params[:id].to_i
    @biz_locations  = @location_level.biz_locations
    display @location_level
  end

  def update

    # INITIALIZING VARIABLES USED THROUGHTOUT

    message = {}

    # GATE-KEEPING

    location_level_id   = params[:id]
    location_level_name = params[:location_level][:name]

    # VALIDATIONS

    message[:error] = "Location Name cannot be blank" if location_level_name.blank?
    @location_level = LocationLevel.get location_level_id

    # OPERATIONS PERFORMED
    if message[:error].blank?
      begin
        @location_level.name = location_level_name
        if @location_level.save
          message = {:notice => "Location Level successfully updated"}

        else
          message = {:error => @location_level.errors.first.join(', ')}
        end
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    redirect resource(@location_level), :message => message

  end

  def fetch_locations
    @colName = ["id" , "name", 'biz_location_address', 'creation_date']
    @colCount = params[:iColumns]
    order = [@colName[params[:iSortCol_0].to_i]]
    location_level = LocationLevel.get(params[:id])
    @locations = location_level.biz_locations(:order => order,
      :limit => params[:iDisplayLength].to_i,
      :offset => params[:iDisplayStart].to_i,
      :conditions => [ 'id LIKE ? OR name LIKE ? OR biz_location_address LIKE ? OR creation_date LIKE ?', '%'+params[:sSearch]+'%', '%'+params[:sSearch]+'%','%'+params[:sSearch]+'%','%'+params[:sSearch]+'%'])
    @iTotalRecords = location_level.biz_locations.count
    @iTotalDisplayRecords = params[:sSearch].blank? ? @iTotalRecords : @locations.size
    @sEcho = params[:sEcho].to_i
    display @location, :layout => layout?
  end

    def fetch_child_locations
    @colName = ["id" , "name", 'biz_location_address', 'creation_date']
    @colCount = params[:iColumns]
    order = [@colName[params[:iSortCol_0].to_i]]
    location_level = LocationLevel.get(params[:id])
    @locations = location_level.biz_locations(:order => order,
      :limit => params[:iDisplayLength].to_i,
      :offset => params[:iDisplayStart].to_i,
      :conditions => [ 'id LIKE ? OR name LIKE ? OR biz_location_address LIKE ? OR creation_date LIKE ?', '%'+params[:sSearch]+'%', '%'+params[:sSearch]+'%','%'+params[:sSearch]+'%','%'+params[:sSearch]+'%'])
    @iTotalRecords = location_level.biz_locations.count
    @iTotalDisplayRecords = params[:sSearch].blank? ? @iTotalRecords : @locations.size
    @sEcho = params[:sEcho].to_i
    display @location, :layout => layout?
  end

  def destroy
  end

end 
