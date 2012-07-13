class AssetCategories < Application
  # provides :xml, :yaml, :js

  def index
    @asset_categories = AssetCategory.all
    display @asset_categories
  end

  #auto-generated
  #def show(id)
  #  @asset_category = AssetCategory.get(id)
  #  raise NotFound unless @asset_category
  #  display @asset_category
  #end

  def show
    @asset_category = AssetCategory.get params[:id]
    @asset_sub_categories = @asset_category.asset_sub_categories
    display @asset_category
  end

  def new
    only_provides :html
    @asset_category = AssetCategory.new
    display @asset_category
  end

  def edit(id)
    only_provides :html
    @asset_category = AssetCategory.get(id)
    raise NotFound unless @asset_category
    display @asset_category
  end

  #auto-generated
  #def create(asset_category)
  #  @asset_category = AssetCategory.new(asset_category)
  #  if @asset_category.save
  #    redirect resource(@asset_category), :message => {:notice => "AssetCategory was successfully created"}
  #  else
  #    message[:error] = "AssetCategory failed to be created"
  #    render :new
  #  end
  #end

  def create
    @asset_category = AssetCategory.new({:name=> params[:name]})
    if @asset_category.save
      redirect resource(:asset_categories), :message => {:notice => "Save Successfully"}
    else
      redirect resource(:asset_categories), :message => {:error => error_messages(@asset_category)}
    end
  end


  def update(id, asset_category)
    @asset_category = AssetCategory.get(id)
    raise NotFound unless @asset_category
    if @asset_category.update(asset_category)
       redirect resource(@asset_category)
    else
      display @asset_category, :edit
    end
  end

  def destroy(id)
    @asset_category = AssetCategory.get(id)
    raise NotFound unless @asset_category
    if @asset_category.destroy
      redirect resource(:asset_categories)
    else
      raise InternalServerError
    end
  end

end # AssetCategories
