class Encumberances < Application
  # provides :xml, :yaml, :js

  def index
    @encumberances = Encumberance.all
    display @encumberances
  end

  def show(id)
    @encumberance = Encumberance.get(id)
    raise NotFound unless @encumberance
    display @encumberance
  end

  def new
    only_provides :html
    @encumberance = Encumberance.new
    display @encumberance
  end

  def edit(id)
    only_provides :html
    @encumberance = Encumberance.get(id)
    raise NotFound unless @encumberance
    display @encumberance
  end

  def create(encumberance)
    # INITIALIZING VARIABLES USED THROUGHTOUT
    @errors = []
    facade = FacadeFactory.instance.get_instance(FacadeFactory::LOAN_ASSIGNMENT_FACADE, User.first)
    @encumberance = Encumberance.new(encumberance)

    # GATE-KEEPING
    name = params[:encumberance][:name]
    amount = params[:encumberance][:assigned_value]
    effective_on = params[:encumberance][:effective_on]

    # VALIDATIONS
    @errors << "Name cannot be blank" if name.blank?
    @errors << "Amount cannot be blank" if amount.blank?
    @errors << "Date of commencement cannot be blank" if effective_on.blank?

    # OPERATIONS
    if @errors.blank?
      @money = MoneyManager.get_money_instance(amount)
      encum = facade.create_encumberance(name, effective_on, @money)
      if encum
        redirect resource(:encumberances), :message => {:notice => "Encumberance was successfully created"}
      else
        message[:error] = "Encumberance failed to be created"
        render :new
      end
    else
      message[:error] = @errors.flatten.join(', ')
      render :new
    end
  end

  def update(id, encumberance)
    @encumberance = Encumberance.get(id)
    raise NotFound unless @encumberance
    if @encumberance.update(encumberance)
      redirect resource(@encumberance)
    else
      display @encumberance, :edit
    end
  end

  def destroy(id)
    @encumberance = Encumberance.get(id)
    raise NotFound unless @encumberance
    if @encumberance.destroy
      redirect resource(:encumberances)
    else
      raise InternalServerError
    end
  end

  def upload_data(id)
    @id=id
    @encumberance=Encumberance.get(id)
    @upload = Upload.new
    display @upload
  end

end # Encumberances
