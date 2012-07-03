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
    message[:error] = "Creation Date cannot be blank" if l_name.blank?

    # OPERATIONS PERFORMED
    if message[:error].blank?
      begin
        location_level = LocationLevel.create_next_level(l_name, l_creation_date)
        if location_level.new?
          message = {:notice => "Location Level creation fail"}
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

  def update
  end

  def destroy
  end

end 
