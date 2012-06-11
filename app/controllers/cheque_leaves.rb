class ChequeLeaves < Application
  before :ensure_authenticated

  def index
    @bank_accounts = BankAccount.all
    display @bank_accounts
  end

  def show(id)
    @cheque_leaf = ChequeLeaf.get(id)
    raise NotFound unless @cheque_leaf
    display @cheque_leaf
  end

  def new(id)
    only_provides :html
    # GATE-KEEPING
    @account_id=id

    # VALIDATION
    if BankAccount.get(@account_id).nil?
      redirect(params[:return], :message => {:notice => "Account not found"})
    end
    # OPERATIONS PERFORMED

    begin

    rescue => ex
      @errors.push(ex.message)
    end

    # POPULATING RESPONSE AND OTHER VARIABLES
    @cheque_leaf = ChequeLeaf.new
    @cheque_leaf.bank_account_id=@account_id
    @bank_account = BankAccount.get(@account_id)
    @cheque_leaves = @bank_account.cheques

    # RENDER/RE-DIRECT
    display @cheque_leaf
  end

  def edit(id)
    only_provides :html
    @cheque_leaf = ChequeLeaf.get(id)
    raise NotFound unless @cheque_leaf
    display @cheque_leaf
  end

  def create
    # GATE-KEEPING
    @account_id=params[:account_id]
    @start=params[:start_serial].to_i
    @end=params[:end_serial].to_i

    # VALIDATION
    if BankAccount.get(@account_id).nil?
      redirect(params[:return], :message => {:notice => "Account not found"})
    end

    if @start<100000 || @start>1000000 ||@end<100000 || @end>1000000
      redirect(params[:return], :message => {:notice => "Invalid serial numbers, Serial number should be 6 digits positive integer"})
    end

    if @start>@end
      redirect(params[:return], :message => {:notice => "Starting serial number cannot be greater than ending serial number"})
    end

    # OPERATIONS PERFORMED
    begin
      @message=String.new
      @unsuccessful=String.new
      @successful=String.new
      @already_present=String.new
      @user=session.user
      (@end-@start+1).times do |serial_no|
        #ChequeLeaf.create!(:serial_no=>serial_no+@start, :bank_account_id=>@account_id, :created_by_user_id=>Session.user.id)
        if ChequeLeaf.all(:serial_no=>serial_no+@start, :bank_account_id=>@account_id).count!=0
          @already_present=@already_present+"#{serial_no+@start}   "
        elsif ChequeLeaf.create!(:serial_no=>serial_no+@start, :bank_account_id=>@account_id, :created_by_user_id=>session.user.id)
          @successful=@successful+"#{serial_no+@start}   "
        else
          @unsuccessful=@unsuccessful+"#{serial_no+@start}   "
        end
      end
    rescue => ex
      #@message+=ex.message
    end

    if @successful.length!=0
      @message+="Successfully created cheque leaves : #{@successful}\n"
    end
    if @unsuccessful.length!=0
      @message+="Failed to create cheque leaves : #{@unsuccessful}\n"
    end
    if @already_present.length!=0
      @message+="Already existing cheque leaves : #{@already_present}"
    end

    # RENDER/RE-DIRECT
    redirect(resource(:cheque_leaves), :message => {:notice => @message})
  end

  def update(id, cheque_leaf)
    @cheque_leaf = ChequeLeaf.get(id)
    raise NotFound unless @cheque_leaf
    if @cheque_leaf.update(cheque_leaf)
      redirect resource(@cheque_leaf)
    else
      display @cheque_leaf, :edit
    end
  end

  def destroy(id)
    @cheque_leaf = ChequeLeaf.get(id)
    raise NotFound unless @cheque_leaf
    if @cheque_leaf.destroy
      redirect resource(:cheque_leaves)
    else
      raise InternalServerError
    end
  end
  
  def mark_invalid(id)
    @id=id
    @cheque_leaf=ChequeLeaf.get(id)
    @cheque_leaf.update!(:valid => false)
    redirect("/ChequeLeaves/new/#{@cheque_leaf.bank_account_id}")
  end

end # ChequeLeaves
