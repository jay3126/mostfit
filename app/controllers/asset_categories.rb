class AssetCategories < Application
  # provides :xml, :yaml, :js

  def index
    @asset_categories = AssetCategory.all
    display @asset_categories
  end

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

  def create
    @asset_category = AssetCategory.new({:name => params[:name]})
    if @asset_category.save
      redirect resource(@asset_category), :message => {:notice => "Asset Category: '#{@asset_category.name} (id: #{@asset_category.id})' was successfully created"}
    else
      redirect resource(:asset_categories), :message => {:error => "Asset Category failed to be created because : #{@asset_category.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
    end
  end

  def update(id, asset_category)
    @asset_category = AssetCategory.get(id)
    raise NotFound unless @asset_category
    if @asset_category.update(asset_category)
      redirect resource(@asset_category), :message => {:notice => "Asset Category: '#{@asset_category.name} (id: #{@asset_category.id})' was successfully updated"}
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
