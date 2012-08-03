class PslSubCategories < Application
  # provides :xml, :yaml, :js

  def index
    @psl_sub_categories = PslSubCategory.all
    display @psl_sub_categories
  end

  def show(id)
    @psl_sub_category = PslSubCategory.get(id)
    raise NotFound unless @psl_sub_category
    display @psl_sub_category
  end

  def new
    only_provides :html
    @psl_sub_category = PslSubCategory.new
    display @psl_sub_category
  end

  def edit(id)
    only_provides :html
    @psl_sub_category = PslSubCategory.get(id)
    raise NotFound unless @psl_sub_category
    display @psl_sub_category
  end

  def create(psl_sub_category)
    @psl_sub_category = PslSubCategory.new(psl_sub_category)
    if @psl_sub_category.save
      redirect resource(@psl_sub_category), :message => {:notice => "PSL SubCategory was successfully created"}
    else
      message[:error] = "PSL SubCategory failed to be created"
      render :new
    end
  end

  def update(id, psl_sub_category)
    @psl_sub_category = PslSubCategory.get(id)
    raise NotFound unless @psl_sub_category
    if @psl_sub_category.update(psl_sub_category)
       redirect resource(@psl_sub_category)
    else
      display @psl_sub_category, :edit
    end
  end

  def destroy(id)
    @psl_sub_category = PslSubCategory.get(id)
    raise NotFound unless @psl_sub_category
    if @psl_sub_category.destroy
      redirect resource(:psl_sub_categories)
    else
      raise InternalServerError
    end
  end

end # PslSubCategories
