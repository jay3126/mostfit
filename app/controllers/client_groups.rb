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
    request.xhr? ? display([@client_group], "client_groups/new", :layout => false) : display([@client_group], "client_groups/new")
  end

  def edit(id)
    only_provides :html
    @client_group = ClientGroup.get(id)
    raise NotFound unless @client_group
    display @client_group
  end

  def create(client_group)
    only_provides :html, :json, :xml
    @client_group = ClientGroup.new(client_group)
    if @client_group.save
      if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
        display @client_group
      else
        request.xhr? ? display(@client_group) : redirect( request.referer, :message => {:notice => "Group was successfully created"})
      end
    else
      if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
        display @client_group
      else
        message[:error] = "Group failed to be created"
        request.xhr? ? display(@client_group.errors, :status => 406) : render(:new)
      end
    end
  end

  def update(id, client_group)
    @client_group = ClientGroup.get(id)
    raise NotFound unless @client_group
    @client_group.attributes = client_group
    if @client_group.save
      message  = {:notice => "Group was successfully edited"}      
      if params[:return] and not params[:return].blank?
        redirect(params[:return], :message => message)
      else
        (@client) ? redirect(resource(@client_group.client), :message => message) : redirect(resource(@client_group), :message => message)
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
      raise NotFound unless @client_group
    end
  end
end # ClientGroups
