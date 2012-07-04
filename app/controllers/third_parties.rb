class ThirdParties < Application
  provides :xml, :yaml, :js
  include DateParser

  def index
    @third_parties = @third_parties || ThirdParty.all
    display @third_parties.sort! { |a,b| a.name.downcase <=> b.name.downcase }.paginate(:page => params[:page], :per_page => 15)
  end

  def show
    @third_party =ThirdParty.get(params[:id])
    @user=User.get(@third_party.recorded_by).login
    display @third_party
  end
  
  def new
    @third_party=ThirdParty.new
    display @third_party
  end
  
  def create
    @third_party = ThirdParty.new(params[:third_party])
    @third_party.recorded_by = session.user.id
    if @third_party.save
      redirect(params[:return]||resource(:third_parties), :message => {:notice => "Third party '#{@third_party.name}' (Id:#{@third_party.id}) successfully created"})
    else
      message[:error] = "Third Party failed to be created"
      render :new  # error messages will show
    end
  end
end
