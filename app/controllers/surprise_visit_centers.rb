class SurpriseVisitCenters < Application
  # provides :xml, :yaml, :js

  def index

    raise "yes".inspect
    @surprise_visit_centers = SurpriseVisitCenter.all
    display @surprise_visit_centers
  end

  def show(id)
    @surprise_visit_center = SurpriseVisitCenter.get(id)
    raise NotFound unless @surprise_visit_center
    display @surprise_visit_center
  end

  def new
    only_provides :html
    @surprise_visit_center = SurpriseVisitCenter.new
    display @surprise_visit_center
  end

  def edit(id)
    only_provides :html
    @surprise_visit_center = SurpriseVisitCenter.get(id)
    raise NotFound unless @surprise_visit_center
    display @surprise_visit_center
  end

  def create(surprise_visit_center)
    @surprise_visit_center = SurpriseVisitCenter.new(surprise_visit_center)
    if @surprise_visit_center.save
      redirect resource(@surprise_visit_center), :message => {:notice => "SurpriseVisitCenter was successfully created"}
    else
      message[:error] = "SurpriseVisitCenter failed to be created"
      render :new
    end
  end

  def update(id, surprise_visit_center)
    @surprise_visit_center = SurpriseVisitCenter.get(id)
    raise NotFound unless @surprise_visit_center
    if @surprise_visit_center.update(surprise_visit_center)
       redirect resource(@surprise_visit_center)
    else
      display @surprise_visit_center, :edit
    end
  end

  def destroy(id)
    @surprise_visit_center = SurpriseVisitCenter.get(id)
    raise NotFound unless @surprise_visit_center
    if @surprise_visit_center.destroy
      redirect resource(:surprise_visit_centers)
    else
      raise InternalServerError
    end
  end

end # SurpriseVisitCenters
