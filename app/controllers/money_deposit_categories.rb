class MoneyDepositCategories < Application

  def index
    @money_deposit_categories = MoneyDepositCategory.all
    display @money_deposit_categories
  end

  def show(id)
    @money_deposit_category = MoneyDepositCategory.get(id)
    raise NotFound unless @money_deposit_category
    display @money_deposit_category
  end

  def new
    only_provides :html
    @money_deposit_category = MoneyDepositCategory.new
    display @money_deposit_category
  end

  def edit(id)
    only_provides :html
    @money_deposit_category = MoneyDepositCategory.get(id)
    raise NotFound unless @money_deposit_category
    display @money_deposit_category
  end

  def create
    created_by_user_id = params[:created_by_user_id]
    created_by_staff_member_id = params[:created_by_staff_member_id]
    category_name = params[:category_name]

    money_deposit_category = {:created_by_user_id => created_by_user_id, :created_by_staff_member_id => created_by_staff_member_id,
      :category_name => category_name}

    @money_deposit_category = MoneyDepositCategory.new(money_deposit_category)
    if @money_deposit_category.save
      redirect resource(:money_deposit_categories), :message => {:notice => "Money Deposit Category: '#{@money_deposit_category.category_name} (id: #{@money_deposit_category.id})' was successfully created"}
    else
      redirect request.referer, :message => {:error => "Money Deposit Category failed to be created because: #{@money_deposit_category.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
    end
  end

  def destroy(id)
    @money_deposit_category = MoneyDepositCategory.get(id)
    raise NotFound unless @money_deposit_category
    @old_money_deposit_category = @money_deposit_category
    if @money_deposit_category.destroy
      redirect resource(:money_deposit_categories), :message => {:notice => "Money Deposit Category: '#{@old_money_deposit_category.category_name} (id: #{@old_money_deposit_category.id})' has been successfully deleted"}
    else
      raise InternalServerError
    end
  end

  def update(id, money_deposit_category)
    @money_deposit_category = MoneyDepositCategory.get(id)
    raise NotFound unless @money_deposit_category
    if @money_deposit_category.update(money_deposit_category)
      redirect resource(@money_deposit_category), :message => {:notice => "Money Deposit Category: '#{@money_deposit_category.category_name} (id: #{@money_deposit_category.id})' was successfully updated"}
    else
      display @money_deposit_category, :edit
    end
  end
  
end # MoneyDepositCategories
