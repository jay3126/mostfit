class ChecklisterSlice::Responses < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    @responses = Response.all
    display @responses
  end

  def show(id)
    @response = Response.get(id)
    raise NotFound unless @response
    display @response
  end

  def new
    only_provides :html
    @response = Response.new
    display @response
  end

  def edit(id)
    only_provides :html
    @response = Response.get(id)
    raise NotFound unless @response
    display @response
  end

  def create(response)
    @response = Response.new(response)
    if @response.save
      redirect resource(@response), :message => {:notice => "Response was successfully created"}
    else
      message[:error] = "Response failed to be created"
      render :new
    end
  end

  def update(id, response)
    @response = Response.get(id)
    raise NotFound unless @response
    if @response.update(response)
      redirect resource(@response)
    else
      display @response, :edit
    end
  end

  def destroy(id)
    @response = Response.get(id)
    raise NotFound unless @response
    if @response.destroy
      redirect resource(:responses)
    else
      raise InternalServerError
    end
  end

  def view_checklist_responses(id)
    @checklist=Checklist.get(id)
    @responses=@checklist.responses
    @fillers=Filler.all
    display @responses
  end


  def view_response(id, response_id)
    @filler=Filler.get(id)

    @response=Response.get(params[:response_id])
    @checklist=@response.checklist
    @sections=@checklist.sections
    display @responses
  end
  def view_report(response_id,checklist_id)
    @checklist=Checklist.get(checklist_id)
    @response=Response.get(response_id)



  end
end # Responses
