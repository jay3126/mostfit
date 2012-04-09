class Banks < Application

  def index
    @banks =  Bank.all
    display @banks
  end

  def create
    @bank = Bank.new(:name => params[:name], :created_by_user_id => session.user.id)
    if @bank.save
      redirect resource(:banks), :message => {:notice => "Save Successfully"}
    else
      redirect resource(:banks), :message => {:error => "#{@bank.errors.first.to_s}"}
    end
  end

  def show
    @bank = Bank.get params[:id]
    @bank_branches =  @bank.bank_branches
    display @bank
  end
  
end
