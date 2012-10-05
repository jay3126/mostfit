class AssetSubCategories < Application
  # provides :xml, :yaml, :js

  def index
    @asset_sub_categories = AssetSubCategory.all
    display @asset_sub_categories
  end

  def show
    @asset_sub_category = AssetSubCategory.get params[:id]
    @asset_types =  @asset_sub_category.asset_types
    display @asset_sub_category
  end

  def new
    only_provides :html
    @asset_sub_category = AssetSubCategory.new
    display @asset_sub_category
  end

  def edit(id)
    only_provides :html
    @asset_sub_category = AssetSubCategory.get(id)
    raise NotFound unless @asset_sub_category
    display @asset_sub_category
  end

  def create
    @asset_category = AssetCategory.get(params[:asset_category_id])
    @asset_sub_category = @asset_category.asset_sub_categories.new(:name => params[:name])
    if @asset_sub_category.save
      redirect url("asset_categories/#{@asset_sub_category.asset_category.id}/asset_sub_categories/#{@asset_sub_category.id}"), :message => {:notice => "Asset Sub-Category: '#{@asset_sub_category.name} (id: #{@asset_sub_category.id})' was successfully created"}
    else
      redirect resource(@asset_category), :message => {:error => "Asset Sub-Category failed to be created because : #{@asset_sub_category.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
    end
  end

  def update(id, asset_sub_category)
    @asset_sub_category = AssetSubCategory.get(id)
    raise NotFound unless @asset_sub_category
    if @asset_sub_category.update(asset_sub_category)
      redirect url("asset_categories/#{@asset_sub_category.asset_category.id}/asset_sub_categories/#{@asset_sub_category.id}"), :message => {:notice => "Asset Sub-Category: '#{@asset_sub_category.name} (id: #{@asset_sub_category.id})' was successfully updated"}
    else
      display @asset_sub_category, :edit
    end
  end

  def destroy(id)
    @asset_sub_category = AssetSubCategory.get(id)
    raise NotFound unless @asset_sub_category
    if @asset_sub_category.destroy
      redirect resource(:asset_sub_categories)
    else
      raise InternalServerError
    end
  end


end # AssetSubCategories
