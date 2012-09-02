class DocumentTypes < Application
  # provides :xml, :yaml, :js

  def index
    @document_types = DocumentType.all
    display @document_types
  end

  def show(id)
    @document_type = DocumentType.get(id)
    raise NotFound unless @document_type
    display @document_type
  end

  def new
    only_provides :html
    @document_type = DocumentType.new
    display @document_type
  end

  def edit(id)
    only_provides :html
    @document_type = DocumentType.get(id)
    raise NotFound unless @document_type
    display @document_type
  end

  def create
    parent_models  = params[:parent_models].blank? ? '' : params[:parent_models].join(',')
    @document_type = DocumentType.new(:name => params[:document_type][:name], :parent_models => parent_models )
    if @document_type.save
      redirect resource(:document_types), :message => {:notice => "DocumentType was successfully created"}
    else
      message[:error] = "DocumentType failed to be created"
      render :new
    end
  end

  def update(id, document_type)
    @document_type = DocumentType.get(id)
    raise NotFound unless @document_type
    if @document_type.update(document_type)
       redirect resource(:document_types)
    else
      display @document_type, :edit
    end
  end
end # DocumentTypes
