class Guarantors < Application
  # provides :xml, :yaml, :js
  before :get_status, :exclude => ['redirect_to_show']
 


  def index
    @guarantors = @client ? @client.guarantors : Guarantor.all 
    display @guarantors
    
  end

  def show(id)
    @guarantor = Guarantor.get(id)
    raise NotFound unless @guarantor
    display @guarantor
  end

  def new
    only_provides :html
    @guarantor = Guarantor.new
    display @guarantor
  end

  def edit(id)
    debugger
    only_provides :html
    @guarantor ||= Guarantor.get(id)
    raise NotFound unless @guarantor
    display @guarantor
  end

  def create(guarantor)
    @guarantor = Guarantor.new(guarantor)
    @guarantor.client = @client if @client
   
    if @guarantor.save
      redirect resource(@client), :message => {:notice => "Guarantor was successfully created"}
    else
      message[:error] = "Guarantor failed to be created"
      render :new
    end
  end


  def update(id, guarantor)
    debugger
    @guarantor = Guarantor.get(id)
    raise NotFound unless @guarantor
    if @guarantor.update(guarantor)
      # redirect resource(:guarantors)
      redirect resource(@client)
    else
      display @guarantor, :edit
    end
  end

  def destroy(id)
    @guarantor = Guarantor.get(id)
    raise NotFound unless @guarantor
    if @guarantor.destroy
      redirect resource(:guarantors)
    else
      raise InternalServerError
    end
  end

  def redirect_to_show(id)
    raise NotFound unless @guarantor = Guarantor.get(id)
    if @guarantor.client
      redirect resource(@guarantor.client,@guarantor)
    else
      redirect resource(@guarantor, :edit)
    end
  end

  private
  def get_status
    debugger
    if params[:client_id] 

      @client = Client.get(params[:client_id])
      raise NotFound unless @client
    end
  end


end # Guarantors
