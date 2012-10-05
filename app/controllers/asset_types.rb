class AssetTypes < Application
  # provides :xml, :yaml, :js

  def index
    @asset_types = AssetType.all
    display @asset_types
  end

  def show
    @asset_type = AssetType.get params[:id]
    display @asset_type
  end

  def new
    only_provides :html
    @asset_type = AssetType.new
    display @asset_type
  end

  def edit(id)
    only_provides :html
    @asset_type = AssetType.get(id)
    raise NotFound unless @asset_type
    display @asset_type
  end

  def create
    @asset_sub_category = AssetSubCategory.get(params[:asset_sub_category_id])
    @asset_type =  @asset_sub_category.asset_types.new(:name => params[:name])
    if @asset_type.save
      redirect url("asset_categories/#{@asset_sub_category.asset_category.id}/asset_sub_categories/#{@asset_sub_category.id}/asset_types/#{@asset_type.id}"), :message => {:notice => "Asset Type: '#{@asset_type.name} (id: #{@asset_type.id})' was successfully created"}
    else
      redirect request.referer, :message => {:error => "Asset Type failed to be created because : #{@asset_type.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
    end
  end

  def update(id, asset_type)
    @asset_type = AssetType.get(id)
    raise NotFound unless @asset_type
    if @asset_type.update(asset_type)
      redirect url("asset_categories/#{@asset_sub_category.asset_category.id}/asset_sub_categories/#{@asset_sub_category.id}/asset_types/#{@asset_type.id}"), :message => {:notice => "Asset Type: '#{@asset_type.name} (id: #{@asset_type.id})' was successfully updated"}
    else
      display @asset_type, :edit
    end
  end

  def destroy(id)
    @asset_type = AssetType.get(id)
    raise NotFound unless @asset_type
    if @asset_type.destroy
      redirect resource(:asset_types)
    else
      raise InternalServerError
    end
  end

end # AssetTypes
