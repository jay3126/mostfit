class Documents < Application
  before :get_parent, :only => [:index, :new, :edit, :create]

  # provides :xml, :yaml, :js
  def index
    @documents = Document.all(:parent_id => @parent.id, :parent_model => @parent.model, :valid_upto.gte => Date.today)
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
      message = {:notice => "Document was successfully created"}
      redirect url("user_locations/weeksheet_collection/#{@parent.id}"), :message => message
    else
      render :new
    end
  end

  def update(id, document)
    @document = Document.get(id)
    raise NotFound unless @document
    if @document.update(document)
      message = {:notice => "Document was successfully created"}
      redirect url("user_locations/weeksheet_collection/#{@document.parent.id}"), :message => message
    else
      display(@document.parent ? @document.parent : :documents)
    end
  end

  def destroy(id)
    @document = Document.get(id)
    raise NotFound unless @document
    if @document.destroy
      redirect resource(:documents)
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