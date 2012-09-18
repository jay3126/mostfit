class ChequeBooks < Application

  def index
    @bank_accounts = BankAccount.all
    display @bank_accounts
  end

  def show(id)
    @cheque_book = ChequeBook.get(id)
    raise NotFound unless @cheque_book
    @cheque_leaves = @cheque_book.cheque_leaves
    display @cheque_leaves
  end

  def new
    only_provides :html
    # GATE-KEEPING
    if request.method == :get and params[:cheque_issue_date].nil?
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
      @cheque_book = ChequeBook.new
      @cheque_book.bank_account_id = @account_id
      @bank_account = BankAccount.get(@account_id)
      @cheque_books = ChequeBook.all(:bank_account_id => @bank_account.id)

      # RENDER/RE-DIRECT
      display @cheque_books
    else
      @account_id = params[:bank_account_id]
      create
    end
  end

  def edit(id)
    only_provides :html
    @cheque_book = ChequeBook.get(id)
    raise NotFound unless @cheque_book
    display @cheque_book
  end

  def create
    message = {}

    # GATE-KEEPING
    @bank_account_id = params[:bank_account_id]
    @start_serial = params[:cheque_book][:start_serial]
    @end_serial = params[:cheque_book][:end_serial]
    @issue_date = params[:cheque_book][:issue_date]

    # VALIDATION
    message[:error] = "Account not found" if BankAccount.get(@bank_account_id.to_i).nil?
    message[:error] = "Please enter Start cheque number" if @start_serial.blank?
    message[:error] = "Please enter End cheque number" if @end_serial.blank?
    message[:error] = "Please provide start and end cheque number" if (@start_serial.blank? and @end_serial.blank?)
    message[:error] = "Start serial number cannot be greater than end serial number" if (@start_serial > @end_serial and (not (@end_serial.blank? and @start_serial.blank?)))
    message[:error] = "End serial number cannot be less than start serial number" if (@end_serial < @start_serial and (not (@end_serial.blank? and @start_serial.blank?)))

    # OPERATIONS PERFORMED
    if message[:error].blank?
      cheque_book = {:start_serial => @start_serial.to_i, :end_serial => @end_serial.to_i, :issue_date => @issue_date, :created_by_user_id => session.user.id, :bank_account_id => @bank_account_id.to_i}
      @cheque_book = ChequeBook.new(cheque_book)
      if @cheque_book.save!
        message = {:notice => "Cheque Book from serial number: '#{@start_serial} to #{@end_serial}' successfully created under Bank Branch Account: '#{@cheque_book.bank_account.name}'"}
        #creating cheque leaves for above created cheque book.
        (@cheque_book.start_serial..@cheque_book.end_serial).each do |book|
          cheque_leaf = {:serial_number => book, :cheque_book_id => @cheque_book.id, :issued_by_staff => session.user.staff_member.id, :bank_account_id => @cheque_book.bank_account_id, :bank_branch_id => @cheque_book.bank_account.bank_branch.id, :biz_location_id => @cheque_book.bank_account.bank_branch.biz_location_id}
          @cheque_leaf = ChequeLeaf.new(cheque_leaf)
          @cheque_leaf.save!
        end
      else
        message = {:error => "Cheque Book falied to be created because : #{@cheque_book.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
      end
    end

    #REDIRECT/RENDER
    if message[:error].blank?
      redirect request.referer, :message => message
    else
      redirect request.referer, :message => message
    end
  end

  def update(id, cheque_book)
    @cheque_book = ChequeBook.get(id)
    raise NotFound unless @cheque_book
    if @cheque_book.update(cheque_book)
      redirect resource(@cheque_book)
    else
      display @cheque_book, :edit
    end
  end

  def destroy(id)
    @cheque_book = ChequeBook.get(id)
    raise NotFound unless @cheque_book
    if @cheque_book.destroy
      redirect resource(:cheque_books)
    else
      raise InternalServerError
    end
  end
  
  # def mark_invalid(id)
  #   @id = id
  #   @cheque_book = ChequeBook.get(id)
  #   @cheque_book.update!(:valid => false)
  #   redirect url("cheque_books/new/#{@cheque_book.bank_account_id}"), :message => {:notice => "Cheque Leaves marked as In-Valid successfully"}
  # end

  # def mark_valid(id)
  #   @cheque_leaf = ChequeLeaf.get(id)
  #   @cheque_leaf.update!(:valid => true)
  #   redirect url("cheque_leaves/new/#{@cheque_leaf.bank_account_id}"), :message => {:notice => "Cheque Leaves marked as Valid successfully"}
  # end

end # ChequeBooks
