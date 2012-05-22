class Designations < Application

  def index
    @designations = Designation.all
    @designation = Designation.new
    display @designations
  end

  def new

  end

  def create
    # INITIALIZING VARIABLES USED THROUGHTOUT

    message = {}

    # GATE-KEEPING

    name =  params[:designation][:name]
    location_level_id = params[:designation][:location_level]

    # VALIDATIONS

    message[:error] = " Please select Location Level." if location_level_id.blank?
    message[:error] = " Name cannot be blank" if name.blank?

    # OPERATIONS PERFORMED
    if message[:error].blank?
      begin
        location_level = LocationLevel.get location_level_id
        designation = Designation.new(:name => name, :location_level => location_level)
        if designation.save
          message = {:notice => "Designation successfully created"}
        else
          message = {:error => designation.errors.collect{|error| error}.flatten.join(', ')}
        end
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    redirect resource(:designations), :message => message

  end
end