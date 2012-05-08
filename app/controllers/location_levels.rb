class LocationLevels < Application

  def index
    @location_levels = LocationLevel.all
    level = @location_levels.blank? ? 0 : @location_levels.last.level + 1
    @location_level = LocationLevel.new(:level => level)
    display @location_levels
  end

  def edit
  end

  def create

    # INITIALIZING VARIABLES USED THROUGHTOUT

    message = {}
    l_level = params[:location_level][:level]
    l_name = params[:location_level][:name]

    # GATE-KEEPING

    l_level =  params[:location_level][:level].to_i
    l_name = params[:location_level][:name]

    # VALIDATIONS

    message[:error] = "Location Level cannot be blank !" if l_level.blank?
    message[:error] = "Location Level is not valid !" if l_level =! LocationLevel.location_level_for_new
    message[:error] = "Location Name cannot be blank !" if l_name.blank?

    # OPERATIONS PERFORMED
    debugger
    if message[:error].blank?
      begin
        location_level = LocationLevel.new(:level => l_level, :name => l_name)
        if location_level.save
          message = {:notice => "Location Level successfully created"}
        else
          message = {:error => "Location Level creation fail"}
        end
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    redirect resource(:location_levels), :message => message
  
  end

  def update
  end

  def destroy
  end

end 
