class Banks < Application

  def index
    @banks =  Bank.all
    display @banks
  end

  def create
    @message = {}
    bank_branches = params[:bank_branch]
    @message[:error] = "Bank Branch Name must be uniqe" if bank_branches.uniq.size != bank_branches.size
    @bank = Bank.new(:name => params[:name], :created_by_user_id => session.user.id)
    if @message[:error].blank?
      if @bank.save
        bank_branches.each do |branch|
          @bank.bank_branches.new(:name => branch, :created_by_user_id => session.user.id).save
        end
        @message[:notice] = "Save Successfully"
      else
        @message[:error] = @bank.errors.first.join(', ')
      end
    end

    if @message[:error].blank?
      redirect resource(:banks), :message => {:notice => "Save Successfully"}
    else
      redirect resource(:banks), :message => {:error => @message[:error]}
    end
  end

  def show
    @bank = Bank.get params[:id]
    @bank_branches = @bank.bank_branches
    display @bank
  end
  
end
