class Home < Application

  def index
    @location_levels = LocationLevel.all
    display @location_levels
  end
end