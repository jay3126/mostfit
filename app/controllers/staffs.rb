class Staffs < Application


  def index
    @staffs = Staff.all
    @staff =  Staff.new
    display @staffs
  end

  def new

  end

  def create
    # INITIALIZING VARIABLES USED THROUGHTOUT

    @message = {}

    # GATE-KEEPING

    name =  params[:staff][:name]

    #VALIDATIONS

    @message[:error] = "Name cannot be blank " if name.blank?

    # OPERATIONS PERFORMED

    if @message[:error].blank?

      @staff = Staff.new(:name => name)
      if @staff.save
        @message[:notice] = "Staff User successfully created"
      else
        @message[:error] = "Sraff User creation fail"
      end
    end

    # REDIRECTION/RENDER

    redirect resource(:staffs), @message
  end

  def edit

  end

  def update
    
  end
end