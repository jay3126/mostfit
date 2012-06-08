class ThirdParties < Application
  provides :xml, :yaml, :js
  include DateParser
  
  def index
    if session.user.role == :admin
      @third_parties = @third_parties || ThirdParty.all
      display @third_parties.sort! { |a,b| a.name.downcase <=> b.name.downcase }.paginate(:page => params[:page], :per_page => 15)
    else
      redirect(params[:return], :message => {:notice => "You dont have sufficient privilleges"})
    end
  end
  
  def show
    if session.user.role == :admin
      @third_party =ThirdParty.get(params[:id])
      raise ArgumentError, "Sorry! Page not found" if @third_party.blank?
      @user=User.get(@third_party.recorded_by).login
      display @third_party
    else
      @third_parties = @third_parties || ThirdParty.all
      redirect(params[:return], :message => {:notice => "You dont have sufficient privilleges"})
    end
  end
  
  def new
    if session.user.role == :admin
      @third_party=ThirdParty.new
      display @third_party
    else
      redirect(params[:return], :message => {:notice => "You dont have sufficient privilleges"})
    end
  end
  
  def create
    if session.user.role == :admin
      @errors = []
      @errors << "Third Party name must not be blank " if params[:third_party][:name].blank?
      if @errors.blank?
        @third_party = ThirdParty.new(params[:third_party])
        @third_party.recorded_by = session.user.id
        if(ThirdParty.all(:name => @third_party.name).count==0)
          if @third_party.save!
            redirect(params[:return]||resource(:third_parties), :message => {:notice => "Third party '#{@third_party.name}' (Id:#{@third_party.id}) successfully created"})
          else
            message[:error] = "Third Party failed to be created"
            render :new
          end
        else
          message[:error] = "Third Party with same name already exists !"
          render :new
        end
      else
        redirect(params[:return], :message => {:notice => "You dont have sufficient privilleges"})
      end
    else
      message[:error] = @errors.to_s
      render :new
    end
  end  
end
