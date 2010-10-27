class ExpenseHeads < Application
  # provides :xml, :yaml, :js

  def index
    @expense_heads = ExpenseHead.all
    display @expense_heads
  end

  def show(id)
    @expense_head = ExpenseHead.get(id)
    raise NotFound unless @expense_head
    display @expense_head
  end

  def new
    only_provides :html
    @expense_head = ExpenseHead.new
    display @expense_head
  end

  def edit(id)
    only_provides :html
    @expense_head = ExpenseHead.get(id)
    raise NotFound unless @expense_head
    display @expense_head
  end

  def create(expense_head)
    @expense_head = ExpenseHead.new(expense_head)
    if @expense_head.save
      redirect resource(:expense_heads), :message => {:notice => "Expense Head was successfully created"}
    else
      message[:error] = "Expense Head failed to be created"
      render :new
    end
  end

  def update(id, expense_head)
    @expense_head = ExpenseHead.get(id)
    raise NotFound unless @expense_head
    if @expense_head.update(expense_head)
       redirect resource(:expense_heads)
    else
      display @expense_head, :edit
    end
  end

  def destroy(id)
    @expense_head = ExpenseHead.get(id)
    raise NotFound unless @expense_head
    if @expense_head.destroy
      redirect resource(:expense_heads)
    else
      raise InternalServerError
    end
  end

end # ExpenseHeads
