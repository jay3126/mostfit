class UserRoles < Application

  def index
    @user_roles = UserRole.all
    @user_role = UserRole.new
    display @user_roles
  end

  def new

  end

  def create

    # INITIALIZING VARIABLES USED THROUGHTOUT

    message = {}

    # GATE-KEEPING

    name =  params[:user_role][:name]
    role_class = params[:user_role][:role_class]
    designation_id = params[:user_role][:designation]

    # VALIDATIONS

    message[:error] = " Please select Designation" if designation_id.blank?
    message[:error] = " Please select Role Class" if role_class.blank?
    message[:error] = " Name cannot be blank" if name.blank?

    # OPERATIONS PERFORMED
    if message[:error].blank?
      begin
        designation = Designation.get designation_id
        user_role = designation.user_roles.new(:name => name, :role_class => role_class)
        if user_role.save
          message = {:notice => "User Role successfully created"}
        else
          message = {:error => user_role.errors.collect{|error| error}.flatten.join(', ')}
        end
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    redirect resource(:user_roles), :message => message

  end
end