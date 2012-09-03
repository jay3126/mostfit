class ChequeLeaves < Application

  def index
    @bank_accounts = BankAccount.all
    display @bank_accounts
  end

  def show(id)
    @cheque_leaf = ChequeLeaf.get(id)
    raise NotFound unless @cheque_leaf
    display @cheque_leaf
  end

  def new
    only_provides :html
    # GATE-KEEPING
    if request.method == :get
      @account_id = params[:id]

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
      @cheque_leaf.bank_account_id = @account_id
      @bank_account = BankAccount.get(@account_id)
      @cheque_leaves = @bank_account.cheques

      # RENDER/RE-DIRECT
      display @cheque_leaf
    else
      @account_id = params[:bank_account_id]
      create
    end
  end

  def edit(id)
    only_provides :html
    @cheque_leaf = ChequeLeaf.get(id)
    raise NotFound unless @cheque_leaf
    display @cheque_leaf
  end

  def create
    # GATE-KEEPING
    @bank_account_id = params[:bank_account_id].to_i
    @start_serial = params[:cheque_leaf][:start_serial].to_i
    @end_serial = params[:cheque_leaf][:end_serial].to_i
    @issue_date = params[:cheque_leaf][:issue_date]

    # VALIDATION
    if BankAccount.get(@bank_account_id).nil?
      redirect(params[:return], :message => {:notice => "Account not found"})
    end

    if @start_serial.blank?
      redirect(params[:return], :message => {:error => "Please enter Start Cheque Number"})
    end

    if @end_serial.blank?
      redirect(params[:return], :message => {:error => "Please enter end Cheque Number"})
    end

    if @issue_date.blank?
      redirect(params[:return], :message => {:error => "Please choose the issue date"})
    end

    if @start_serial > @end_serial
      redirect(params[:return], :message => {:error => "Starting serial number cannot be greater than ending serial number"})
    end

    # OPERATIONS PERFORMED
    cheque_leaf = {:start_serial => @start_serial, :end_serial => @end_serial, :issue_date => @issue_date, :created_by_user_id => session.user.id, :bank_account_id => @bank_account_id}
    @cheque_leaf = ChequeLeaf.new(cheque_leaf)
    if @cheque_leaf.save!
      redirect resource(:cheque_leaves), :message => {:notice => "Cheque Leaves from serial number: '#{@start_serial} to #{@end_serial}' successfully created under Bank Branch Account: '#{@cheque_leaf.bank_account.name}'"}
    else
      redirect request.referer, :message => {:error => "Cheque Leaves falied to be created because : #{@cheque_leaf.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
    end
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
    @id = id
    @cheque_leaf = ChequeLeaf.get(id)
    @cheque_leaf.update!(:valid => false)
    redirect url("cheque_leaves/new/#{@cheque_leaf.bank_account_id}"), :message => {:notice => "Cheque Leaves marked as In-Valid successfully"}
  end

  def mark_valid(id)
    @cheque_leaf = ChequeLeaf.get(id)
    @cheque_leaf.update!(:valid => true)
    redirect url("cheque_leaves/new/#{@cheque_leaf.bank_account_id}"), :message => {:notice => "Cheque Leaves marked as Valid successfully"}
  end

end # ChequeLeaves
