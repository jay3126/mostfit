class Banks < Application

  def index
    @banks =  Bank.all
    display @banks
  end

  def create
    @message = {}
    branch_names = []
    bank_branches = params[:bank_branch].values
    bank_branches.each{|value| branch_names << value[:bank_branch]}
    @message[:error] = "Bank Branch Name must be uniqe" if branch_names.uniq.size != branch_names.size
    @bank = Bank.new(:name => params[:name], :created_by_user_id => session.user.id)
    if @message[:error].blank?
      if @bank.save
        bank_branches.each do |branch|
          @bank.bank_branches.new(:name => branch[:bank_branch], :created_by_user_id => session.user.id, :biz_location_id => branch[:location]).save unless branch[:bank_branch].blank?
        end
        @message[:notice] = "Save Successfully"
      else
        @message[:error] = @bank.errors.first.join(', ')
      end
    end

    if @message[:error].blank?
      redirect resource(@bank), :message => {:notice => "Save Successfully"}
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
