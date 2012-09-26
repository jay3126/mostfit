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

  #def create(response)
  #  @result_status_exists = false
  #  @response = Response.new(:response)
  #  @result_status_check_for_target_entity = Response.get(:result_status => @response.result_status, :target_entity_id => @response.target_entity_id)
  #
  #  if @result_status_check_for_target_entity.exists?
  #    @result_status_exists = true
  #  end
  #
  #  if @result_status_exists == false
  #    @response = Response.new(:response)
  #    if @response.save
  #        redirect resource(@response), :message => {:notice => "Response was successfully created"}
  #    end
  #  else
  #    message[:error] = "Response failed to be created"
  #    render :new
  #  end
  #end


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

  def edit_response(id, response_id)
    @filler=Filler.get(id)

    @response=Response.get(params[:response_id])
    @checklist=@response.checklist
    @sections=@checklist.sections
    display @responses
  end

  def view_report(id,response_id,checklist_id)
    @checklist=Checklist.get(checklist_id)
    @response=Response.get(response_id)
    @sections=@checklist.sections.all(:has_score=>true)

     display @response

  end
end # Responses
