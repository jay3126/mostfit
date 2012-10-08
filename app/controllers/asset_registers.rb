class AssetRegisters < Application
  before :get_context, :exclude => ['redirect_to_show']
  provides :xml, :yaml, :js
  include DateParser

  def index
    if request.xhr? and params[:biz_location_id]
      @asset_registers = AssetRegister.all(:biz_location_id => params[:biz_location_id]).paginate(:page => 1, :per_page => 15, :order => [:issue_date.desc])
      display @asset_registers, :layout => layout?
    else
      @asset_registers = (@asset_registers || AssetRegister.all).paginate(:page => 1, :per_page => 15)
      display @asset_registers, :layout => layout?
    end
  end

  def show(id)
    @asset_register = AssetRegister.get(id)
    raise NotFound unless @asset_register
    display @asset_register, :layout => layout?
  end

  def show_from_biz_location(id)
    @asset_register = AssetRegister.get(id)
    raise NotFound unless @asset_register
    display @asset_register, :layout => layout?
  end

  def new
    only_provides :html
    @asset_register = AssetRegister.new
    @branch = BizLocation.get(params[:biz_location_id]) if params and params.key?(:biz_location_id)
    display @asset_register, :layout => layout?
  end

  def edit(id)
    only_provides :html
    @asset_register = AssetRegister.get(id)
    raise NotFound unless @asset_register
    display @asset_register, :layout => layout?
  end

  def edit_from_biz_location(id)
    only_provides :html
    @asset_register = AssetRegister.get(id)
    raise NotFound unless @asset_register
    display @asset_register, :layout => layout?
  end

  def create
    #first condition is creation of Asset Register from Biz Location page.
    if request.referer.include?("user_locations")
      asset_register = {:issue_date => params[:asset_register][:issue_date], :date => params[:asset_register][:date], :invoice_date => params[:asset_register][:invoice_date], :asset_model => params[:asset_model], :name => params[:name], :invoice_number => params[:invoice_number], :biz_location_id => params[:biz_location_id], :asset_category_id => params[:asset_category_id], :name_of_the_vendor => params[:name_of_the_vendor], :tag_no => params[:tag_no], :name_of_the_item => params[:name_of_the_item], :asset_sub_category_id => params[:asset_sub_category_id], :manager_staff_id => params[:manager_staff_id], :serial_no => params[:serial_no], :make => params[:make], :asset_type_id => params[:asset_type_id]}
      @asset_register = AssetRegister.new(asset_register)
      if @asset_register.save
        redirect url("user_locations/show/#{@asset_register.biz_location_id}"), :message => {:notice => "Asset Entry of '#{@asset_register.name_of_the_item}' was successfully created"}
      else
        redirect url(), :message => {:error => "Asset Entry falied to be created because: #{@asset_register.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
      end
      #following condition is creation of Asset register from Configuration tab.
    else
      asset_register = params[:asset_register]
      @asset_register = AssetRegister.new(asset_register)
      if @asset_register.save
        redirect resource(@asset_register), :message => {:notice => "Asset Entry of '#{@asset_register.name_of_the_item}' was successfully created"}
      else
        message[:error] = "Asset entry failed to be entered"
        render :new #error message will show
      end
    end
  end

  def update(id, asset_register)
    @asset_register = AssetRegister.get(id)
    raise NotFound unless @asset_register
    if @asset_register.update(asset_register)
      if request.referer.include?("edit_from_biz_location")
        redirect url("user_locations/show/#{@asset_register.biz_location_id}"), :message => {:notice => "Asset Entry of '#{@asset_register.name_of_the_item}' was successfully updated"}
      else
        redirect resource(@asset_register), :message => {:notice => "Asset Entry of '#{@asset_register.name_of_the_item}' was successfully updated"}
      end
    else
      display @asset_register, :edit
    end
  end

  def destroy(id)
    @asset_register = AssetRegister.get(id)
    raise NotFound unless @asset_register
    if @asset_register.destroy
      redirect(params[:return] ||resource(@asset_register), :message => {:notice => "Asset entry was successfully deleted"})
    else
      raise InternalServerError
    end
  end

  def delete(id)
    edit(id)
  end

  def redirect_to_show(id) 
    raise NotFound unless @asset_register = AssetRegister.get(id)
    redirect resource(@asset_register)
  end

  private
  def get_context
    @branch = BizLocation.get(params[:biz_location_id]) if params.key?(:biz_location_id)
  end

end # AssetRegisters
