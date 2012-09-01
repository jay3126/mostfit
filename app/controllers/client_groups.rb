class ClientGroups < Application
  provides :xml
  before :get_context, :only => ['edit', 'update', 'index']

  def index
    @client_groups = ClientGroup.all
    display @client_groups
  end

  def show(id)
    @client_group = ClientGroup.get(id)
    raise NotFound unless @client_group
    display @client_group
  end

  def new
    only_provides :html
    @client_group = ClientGroup.new
    if params[:biz_location_id]
      @client_group.biz_location_id = params[:biz_location_id]
      @biz_location = BizLocation.get(params[:biz_location_id])
    end
    request.xhr? ? display([@client_group], "client_groups/new", :layout => false) : display([@client_group], "client_groups/new")
  end

  def edit(id)
    only_provides :html
    @client_group = ClientGroup.get(id)
    raise NotFound unless @client_group
    if @client_group.biz_location
      @biz_location = @client_group.biz_location
    end
    display @client_group
  end

  def create
    only_provides :html, :json, :xml
    if params[:client_group]
      client_group = params[:client_group]
    else
      client_group = {:name => params[:name], :code => params[:code], :number_of_members => params[:number_of_members], :biz_location_id => params[:biz_location_id], :created_by_staff_member_id => params[:created_by_staff_member_id]}
    end
    @biz_location_id = params[:biz_location_id]
    @client_group = ClientGroup.new(client_group)
    if @client_group.save
      if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
        display @client_group
      elsif params[:new_group_from_biz_location]
        redirect url("new_clients/new?biz_location_id=#{@biz_location_id}"), :message => {:notice => "Client Group : '#{@client_group.name} ( Id: #{@client_group.id})' was successfully created"}
      else
        request.xhr? ? display(@client_group) : redirect(:client_groups, :message => {:notice => "Client Group : '#{@client_group.name} ( Id: #{@client_group.id})' was successfully created"})
      end
    else
      if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
        display @client_group
      elsif params[:new_group_from_biz_location]
        redirect url("new_clients/new?biz_location_id=#{@biz_location_id}"), :message => {:error => "Client Group failed to be created because : #{@client_group.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
      else
        message[:error] = "Client Group failed to be created"
        request.xhr? ? display(@client_group.errors, :status => 406) : render(:new)
      end
    end
  end

  def update(id, client_group)
    @client_group = ClientGroup.get(id)
    raise NotFound unless @client_group
    @client_group.attributes = client_group
    @client_group.biz_location = BizLocation.get(client_group[:biz_location_id])
    if @client_group.save
      message  = {:notice => "Client Group was successfully edited"}      
      if params[:return] and not params[:return].blank?
        redirect(params[:return], :message => message)
      else
        (@biz_location) ? redirect(resource(@client_group.biz_location), :message => message) : redirect(resource(@client_group), :message => message)
      end
    else
      display @client_group, :edit
    end
  end

  def destroy(id)
    @client_group = ClientGroup.get(id)
    raise NotFound unless @client_group
    if @client_group.destroy
      redirect resource(:client_groups)
    else
      raise InternalServerError
    end
  end

  private
  def get_context
    if params[:id]
      @client_group = ClientGroup.get(params[:id])
      @biz_location = @client_group.biz_location
    elsif params[:biz_location_id]
      @biz_location = BizLocation.get(params[:biz_location_id])
      raise NotFound unless @biz_location
    end
  end
end # ClientGroups
