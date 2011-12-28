class SurpriseCenterVisits < Application
  # provides :xml, :yaml, :js

  def index
    @surprise_center_visits = SurpriseCenterVisit.all
    display @surprise_center_visits
  end

  def show(id)
    @surprise_center_visit = SurpriseCenterVisit.get(id)
    raise NotFound unless @surprise_center_visit
    display @surprise_center_visit
  end

  def new
    only_provides :html
    @surprise_center_visit = SurpriseCenterVisit.new
    display @surprise_center_visit
  end

  def edit(id)
    only_provides :html
    @surprise_center_visit = SurpriseCenterVisit.get(id)
    raise NotFound unless @surprise_center_visit
    display @surprise_center_visit
  end

  def create(surprise_center_visit)
    @surprise_center_visit = SurpriseCenterVisit.new(surprise_center_visit)
    if @surprise_center_visit.save
      redirect resource(@surprise_center_visit), :message => {:notice => "Surprise Center Visit was successfully created"}
    else
      message[:error] = "Surprise Center Visit failed to be created"
      render :new
    end
  end

  def update(id, surprise_center_visit)
    @surprise_center_visit = SurpriseCenterVisit.get(id)
    raise NotFound unless @surprise_center_visit
    if @surprise_center_visit.update(surprise_center_visit)
       redirect resource(@surprise_center_visit)
    else
      display @surprise_center_visit, :edit
    end
  end

  def destroy(id)
    @surprise_center_visit = SurpriseCenterVisit.get(id)
    raise NotFound unless @surprise_center_visit
    if @surprise_center_visit.destroy
      redirect resource(:surprise_center_visits)
    else
      raise InternalServerError
    end
  end

end # SurpriseCenterVisits
