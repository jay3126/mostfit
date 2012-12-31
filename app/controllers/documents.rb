class Documents < Application
  before :get_parent, :only => [:index, :new, :edit, :create]

  def index
    @documents = Document.all(:parent_id => @parent.id, :parent_model => @parent.model)
    display @documents, :layout => layout?
  end

  def show(id)
    @document = Document.get(id)
    raise NotFound unless @document
    display @document, :layout => layout?
  end

  def new
    only_provides :html
    @document = Document.new
    display @document, :layout => layout?
  end

  def edit(id)
    only_provides :html
    @document = Document.get(id)
    raise NotFound unless @document
    display @document, :layout => layout?
  end

  def create(document)
    @document = Document.new(document)
    @document.parent_model = @parent.class
    @document.parent_id    = @parent.id
    if @document.save
      msg_str = "Document was successfully uploaded"
      if @document.parent_model == "Client"
        redirect url("new_clients/#{@document.parent_id}?success_message=#{msg_str}#documents")
      else
        redirect url("user_locations/weeksheet_collection/#{@document.parent_id}?success_message=#{msg_str}#documents")
      end
    else
      render :new
    end
  end

  def update(id, document)
    @document = Document.get(id)
    raise NotFound unless @document
    if @document.update(document)
      msg_str = "Document was successfully updated"
      if @document.parent_model == "Client"
        redirect url("new_clients/#{@document.parent_id}?success_message=#{msg_str}#documents")
      else
        redirect url("user_locations/weeksheet_collection/#{@document.parent_id}?success_message=#{msg_str}#documents")
      end
    else
      render :edit
    end
  end

  def destroy(id)
    @document = Document.get(id)
    raise NotFound unless @document
    if @document.destroy
      msg_str = "Document was successfully deleted"
      if @document.parent_model == "Client"
        redirect url("new_clients/#{@document.parent_id}?success_message=#{msg_str}#documents")
      else
        redirect url("user_locations/weeksheet_collection/#{@document.parent_id}?success_message=#{msg_str}#documents")
      end
    else
      raise InternalServerError
    end
  end

  private

  def get_parent
    if params[:parent_model] and params[:parent_id]
      @parent = Kernel.const_get(params[:parent_model]).get(params[:parent_id])
    else
      @parent = Mfi.new(Mfi.first ? Mfi.first.attributes : {})
    end
  end
end # Documents