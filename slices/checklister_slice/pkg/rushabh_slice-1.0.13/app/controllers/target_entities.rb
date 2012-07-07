class ChecklisterSlice::TargetEntities < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    @target_entities = TargetEntity.all
    display @target_entities
  end

  def show(id)
    @target_entity = TargetEntity.get(id)
    raise NotFound unless @target_entity
    display @target_entity
  end

  def new
    only_provides :html
    @target_entity = TargetEntity.new
    display @target_entity
  end

  def edit(id)
    only_provides :html
    @target_entity = TargetEntity.get(id)
    raise NotFound unless @target_entity
    display @target_entity
  end

  def create(target_entity)
    @target_entity = TargetEntity.new(target_entity)
    if @target_entity.save
      redirect resource(@target_entity), :message => {:notice => "TargetEntity was successfully created"}
    else
      message[:error] = "TargetEntity failed to be created"
      render :new
    end
  end

  def update(id, target_entity)
    @target_entity = TargetEntity.get(id)
    raise NotFound unless @target_entity
    if @target_entity.update(target_entity)
       redirect resource(@target_entity)
    else
      display @target_entity, :edit
    end
  end

  def destroy(id)
    @target_entity = TargetEntity.get(id)
    raise NotFound unless @target_entity
    if @target_entity.destroy
      redirect resource(:target_entities)
    else
      raise InternalServerError
    end
  end

end # TargetEntities
